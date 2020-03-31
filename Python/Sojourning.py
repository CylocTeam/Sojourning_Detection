import numpy as np
import pandas as pd

def find_stays(accx, accy, accz, timestamp, params):
    # unpack & definitions
    MAX_HIST_BINS = 1e4
    DATA_LEN = len(timestamp)
    MAX_TIME_GAP_PCTL = params["max_time_gap_pctl"]
    NUN_DIMS = 3 # {x y z}
    
    var_th = params["var_th"]
    acc_mat = [accx , accy , accz]  # stacking

    # print(acc_mat)





if __name__ == "__main__":
    df = pd.read_csv("../data/a02_p3.csv")
    print(df.head())

    fs = 25 #[Hz]
    params = {"win_size_sec": 3,
    "ecdf_diff_th": 0.01,
    "var_th": 0.05,
    "abrupt_filt_time_const": 10,
    "abrupt_pctg_th": 0.2,
    "min_stay_duration": 4,
    "max_time_gap_msec": 1e3 * 5 / fs,
    "max_section_gap_minutes": 7,
    "max_time_gap_pctl": 60}

    print(params)

    # is_stay, stay_times, stay_durations = find_stays(df.x, df.y, df.z, df.timestamp, params)
    find_stays(df.x, df.y, df.z, df.timestamp, params)
