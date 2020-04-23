import numpy as np
import pandas as pd
from params import Params
from sojourning import *

#### OUTSIDE ###

fs = 25  # [Hz]
input_params = {
    "win_size_sec": 3,
    "ecdf_diff_th": 0.01,
    "var_th": 0.05,
    "abrupt_filt_const_sec": 10,
    "abrupt_pctg_th": 0.2,
    "min_stay_duration_m": 1,
    "max_time_gap_nsec": 1e9 * 5 / fs,
    "max_section_gap_m": 7,
    "max_time_gap_pctl": 60,
}


def read_csv():
    # read data for testing
    data = pd.read_csv("../data/a02_p3.csv")

    return pd.DataFrame(
        {"x": data.x.to_numpy(), "y": data.y.to_numpy(), "z": data.z.to_numpy()},
        index=pd.to_datetime(data.timestamp, format="%H:%M:%S.%f"),
    )


#### INSIDE ###
NUM_DIMS = 3

# definitions
df = read_csv()
df = df.sort_index()
df["norm"] = df.apply(lambda row: np.sqrt(row.x ** 2 + row.y ** 2 + row.z ** 2), axis=1)
df["diff_ns"] = np.insert(np.diff(df.index.to_numpy().astype("float")), 0, None)
df["is_stay"] = False

params = Params(input_params)
params.convert_filters_sec2smp(df["diff_ns"])
params.set_var_th(df["norm"])

### TODO IMPLEMENT ###
sections_times = find_sections_idx(df["diff_ns"], params)


# go through each section and decide isStay
for sec in range(len(sections_times) - 1):
    # slice df excluding left endpoint
    df_ = df.loc[sections_times[sec] : sections_times[sec + 1]].iloc[:-1]
    is_stay = check_stay_raw(df_, params.win_size_smp, params.var_th, NUM_DIMS)
    df.loc[is_stay.index, "is_stay"] = is_stay

# filter abrupt movements
df.is_stay = filter_abrupt_movements(df.is_stay, params.abrupt_filt_size, params)

# force sectioning
df.is_stay.loc[sections_times] = False


### PROBABLY BETTER TO BE IMPLEMENTED EXTERNALLY ###
# find start & end times
start_times, end_times = find_time_tags(df)
stays = pd.DataFrame({"start_times": start_times, "end_times": end_times})
stays["duration"] = stays.apply(
    lambda row: row["end_times"] - row["start_times"], axis=1
)

# cancle short sojourns
if stays.empty:
    pass  # return stays

stay_long_enough = stays["duration"] > pd.to_timedelta(
    params["min_stay_duration"], unit="m"
)
stays = stays[stay_long_enough]
