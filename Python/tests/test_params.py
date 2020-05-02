import numpy as np
import pandas as pd
import pytest

from Sojourning.params import Params


def read_config():
    df = pd.read_csv("tests/test_config.csv")
    return pd.Series(df.value.values, index=df.name).to_dict()


@pytest.mark.parametrize(
    "attr,value",
    [
        ("ecdf_diff_th", 0.01),
        ("max_time_gap", np.array(200, dtype="timedelta64[ms]")),
        ("_fs", 0),
    ],
)
def test_params_init(attr, value):
    params = Params(read_config())
    assert getattr(params, attr) == value


def test_set_avg_sample_rate():
    p = Params(read_config())
    td = pd.Series(np.append(np.ones(10), 100))
    p.convert_filters_sec2smp(td)
    assert p._fs == 1e9


# if __name__ == "__main__":
#     test_set_avg_sample_rate()
