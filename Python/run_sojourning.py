import numpy as np
import pandas as pd
from params import Params
from sojourning import Sojourning

#### OUTSIDE ###
def read_config():
    config_dict = {
        "win_size_sec": 3,
        "ecdf_diff_th": 0.01,
        "var_th": 0.05,
        "abrupt_filt_const_sec": 10,
        "abrupt_pctg_th": 0.2,
        "min_stay_duration_m": 1,
        "max_time_gap_msec": 200,
        "max_section_gap_m": 7,
        "max_time_gap_pctl": 60,
    }
    return config_dict


def read_csv():
    # read data for testing
    data = pd.read_csv("../data/a02_p3.csv")

    return pd.DataFrame(
        {"x": data.x.to_numpy(), "y": data.y.to_numpy(), "z": data.z.to_numpy()},
        index=pd.to_datetime(data.timestamp, format="%H:%M:%S.%f"),
    )


# definitions
df = read_csv()
soj = Sojourning(df)
input_params = read_config()
params = Params(input_params)

# calc initial pepremters
params.convert_filters_sec2smp(soj.df["diff_ns"])
params.set_var_th(soj.df["norm"])

# go through each section and decide if it is_stay
sections_times = soj.find_sections_idx(params)
for sec in range(len(sections_times) - 1):
    df_slice = soj.get_section_slice(sections_times[sec], sections_times[sec + 1])
    is_stay = Sojourning.calc_stay_raw(df_slice, params.win_size_smp, params.var_th)
    soj.set_is_stay(is_stay)

# filter abrupt movements
soj.filter_abrupt_movements(params.abrupt_filt_size, params.abrupt_pctg_th)

# force sectioning
soj.df.is_stay.loc[sections_times] = False

### PROBABLY BETTER TO BE IMPLEMENTED EXTERNALLY ###
# find start & end times
start_times, end_times = soj.find_time_tags()
stays = pd.DataFrame({"start_times": start_times, "end_times": end_times})
stays["duration"] = stays.apply(
    lambda row: row["end_times"] - row["start_times"], axis=1
)

# cancle short stays
stays.drop(stays[stays.duration <= params.min_stay_duration].index, inplace=True)

# display output
import plotly.express as px

print(stays)
print(params)

fig = px.line(x=soj.df.index, y=soj.df.is_stay.values)
fig.show()
