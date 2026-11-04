"""Pure-Python tests. Run: python -m unittest discover -s tests -v"""
import contextlib
import io
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import Mock

BASE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE / "python"))
from common_functions import (
    CommonError, COMMON_VERSION, DEFAULT_CONFIG, OUTPUT_ROOT, normalize_text,
    parse_config, quote_table_name, validate_identifier, validate_execution_id,
    parse_run_result, run_common_notebook, log_event,
)


class NormalizeTests(unittest.TestCase):
    def test_type_rejected(self):
        for value in (1, 1.2, True, [], {}, b"abc"):
            with self.subTest(value=repr(value)), self.assertRaises(CommonError) as ctx:
                normalize_text(value)
            self.assertEqual(ctx.exception.code, "CMN001")

    def test_nul_rejected(self):
        with self.assertRaises(CommonError) as ctx:
            normalize_text("A\x00B")
        self.assertEqual(ctx.exception.code, "CMN008")

    def test_not_idempotent(self):
        self.assertEqual(normalize_text(normalize_text('"')), '""""')


for case in json.loads((BASE / "tests/normalization_cases.json").read_text(encoding="utf-8")):
    def check(self, case=case):
        self.assertEqual(normalize_text(case["input"]), case["expected"], case["description"])
    setattr(NormalizeTests, "test_" + case["case_id"], check)


class ConfigTests(unittest.TestCase):
    def test_defaults(self):
        self.assertEqual(parse_config("{}"), DEFAULT_CONFIG)

    def test_valid_config(self):
        self.assertTrue(parse_config('{"mode":"table","write_output":true}')["write_output"])

    def test_invalid_json(self):
        for value in ("", "{", "[]", "null", "true", None, " " * 16385):
            with self.subTest(value=repr(value)[:30]), self.assertRaises(CommonError):
                parse_config(value)

    def test_duplicate_keys(self):
        with self.assertRaises(CommonError):
            parse_config('{"mode":"sample","mode":"table"}')

    def test_nonfinite(self):
        for value in ("NaN", "Infinity", "-Infinity"):
            with self.subTest(value=value), self.assertRaises(CommonError):
                parse_config('{"write_output":' + value + '}')

    def test_unknown_key(self):
        with self.assertRaises(CommonError):
            parse_config('{"overwrite":true}')

    def test_invalid_modes(self):
        for value in ("TABLE", "", 0, None, {}, []):
            with self.subTest(value=value), self.assertRaises(CommonError):
                parse_config(json.dumps({"mode": value}))

    def test_boolean_type(self):
        for name in ("write_output", "allow_empty"):
            for value in ("false", 0, 1, None):
                with self.subTest(name=name,value=value), self.assertRaises(CommonError):
                    parse_config(json.dumps({name: value}))

    def test_source_output_collision(self):
        with self.assertRaises(CommonError) as ctx:
            parse_config('{"source_column":"A","output_column":"a"}')
        self.assertEqual(ctx.exception.code, "CMN005")

    def test_valid_identifiers(self):
        for value in ("a", "_a", "a1", "A" * 128, "select"):
            self.assertEqual(validate_identifier(value), value)
        self.assertEqual(quote_table_name("GoldLakehouse.dbo.products"), "`GoldLakehouse`.`dbo`.`products`")
        self.assertEqual(quote_table_name("select"), "`select`")

    def test_invalid_identifiers(self):
        for value in ("", "1a", "a;b", "a`", "a-b", "日本", "a\n", "a"*129, None):
            with self.subTest(value=value), self.assertRaises(CommonError):
                validate_identifier(value)

    def test_invalid_table_names(self):
        for value in ("a..b", "a.b.c.d", ".a", "a.", "../a", None):
            with self.subTest(value=value), self.assertRaises(CommonError):
                quote_table_name(value)

    def test_execution_id(self):
        for value in ("", "../x", "_x", "x/y", "A"*65, None):
            with self.subTest(value=value), self.assertRaises(CommonError):
                validate_execution_id(value)
        self.assertEqual(validate_execution_id("job_01-ABC"), "job_01-ABC")


class CallerTests(unittest.TestCase):
    def setUp(self):
        self.result = {"contract_version":"1.0", "status":"SUCCESS", "execution_id":"test-001",
            "mode":"sample", "row_count":6, "changed_count":4, "null_count":1,
            "output_column":"productitemnamekanji_normalized", "output_path":None,
            "write_output":False, "library_version":COMMON_VERSION}

    def test_valid_return(self):
        self.assertEqual(parse_run_result(json.dumps(self.result), "test-001"), self.result)

    def test_missing_and_extra_fields(self):
        for result in ({k:v for k,v in self.result.items() if k!="row_count"}, {**self.result,"extra":1}):
            with self.subTest(result=result), self.assertRaises(CommonError):
                parse_run_result(json.dumps(result), "test-001")

    def test_bad_return_properties(self):
        updates=[("status","ERROR"),("execution_id","other"),("contract_version","2.0"),
            ("library_version","old"),("row_count",True),("row_count",-1),("row_count",1.0),
            ("changed_count",7),("null_count",7),("mode","INVALID"),("write_output","false"),
            ("output_path","../evil"),("output_column","bad;name")]
        for key,value in updates:
            with self.subTest(key=key,value=value), self.assertRaises(CommonError):
                parse_run_result(json.dumps({**self.result,key:value}), "test-001")

    def test_write_path(self):
        good={**self.result,"write_output":True,"output_path":f"{OUTPUT_ROOT}/test-001"}
        self.assertEqual(parse_run_result(json.dumps(good),"test-001"),good)

    def test_empty_return(self):
        for value in ("", "not-json", "null", "[]"):
            with self.subTest(value=value), self.assertRaises(CommonError):
                parse_run_result(value,"test-001")

    def test_call_and_arguments(self):
        runner=Mock(return_value=json.dumps(self.result))
        self.assertEqual(run_common_notebook(runner,'{}',"test-001"),self.result)
        args=runner.call_args.args
        self.assertEqual(args[:2],("NB_CommonTransform",600))
        self.assertEqual(args[2]["execution_id"],"test-001")
        self.assertEqual(json.loads(args[2]["param_json"]),DEFAULT_CONFIG)
        runner.assert_called_once()

    def test_exception_propagated_without_retry(self):
        runner=Mock(side_effect=TimeoutError("simulated timeout"))
        with self.assertRaises(TimeoutError):
            run_common_notebook(runner,"{}","test-001")
        runner.assert_called_once()

    def test_bad_timeout_before_call(self):
        runner=Mock()
        for value in (0,-1,43201,True,"600",None):
            with self.subTest(value=value), self.assertRaises(CommonError):
                run_common_notebook(runner,"{}","test-001",value)
        runner.assert_not_called()

    def test_parameter_mismatch(self):
        runner=Mock(return_value=json.dumps({**self.result,"mode":"table"}))
        with self.assertRaises(CommonError):
            run_common_notebook(runner,"{}","test-001")

    def test_disallowed_zero_rows(self):
        runner=Mock(return_value=json.dumps({**self.result,"row_count":0,"changed_count":0,"null_count":0}))
        with self.assertRaises(CommonError):
            run_common_notebook(runner,"{}","test-001")
        result=run_common_notebook(runner,'{"allow_empty":true}',"test-001")
        self.assertEqual(result["row_count"],0)

    def test_logging(self):
        out=io.StringIO()
        with contextlib.redirect_stdout(out):
            log_event("INFO","TEST","test-001",row_count=6)
        entry=json.loads(out.getvalue())
        self.assertEqual(entry["metadata"],{"row_count":6})
        self.assertIn("+00:00",entry["timestamp_utc"])


if __name__ == "__main__":
    unittest.main()
