import numpy as np
import pandas as pd


class Sojourning:
    def __init__(self, df):
        self.set_transform_df(df)

    def get_section_slice(self, section_start, section_end):
        return self.df.loc[section_start:section_end].iloc[:-1]

    def set_transform_df(self, df):
        df = df.sort_index()
        df["norm"] = df.apply(
            lambda row: np.sqrt(row.x ** 2 + row.y ** 2 + row.z ** 2), axis=1
        )
        df["diff_ns"] = np.insert(
            np.diff(df.index.to_numpy().astype("float64")), 0, None
        ).astype("int64")
        df["is_stay"] = False
        self.df = df

    def find_sections_idx(self, params):
        # max_section_gap = np.array(params["max_section_gap_minutes"], dtype='timedelta64[m]')
        time_diffs_ns = self.df.diff_ns
        max_section_gap_ns = params.max_section_gap.astype("timedelta64[ns]").astype(
            "int64"
        )

        section_idxs_list = time_diffs_ns[
            time_diffs_ns > max_section_gap_ns
        ].index.to_list()

        section_idxs_list.insert(0, time_diffs_ns.index[0])
        section_idxs_list.append(time_diffs_ns.index[-1])
        return pd.to_datetime(section_idxs_list)

    @staticmethod
    def calc_stay_raw(df, win_size_smp, var_th, num_dims=3):
        df_rollvar = df.rolling(win_size_smp, min_periods=0, center=True).var()
        is_axis_stay = df_rollvar[["x", "y", "z"]] < var_th / num_dims
        is_norm_stay = df_rollvar["norm"] < var_th
        is_stay = is_axis_stay.all(axis=1) & is_norm_stay
        # is_stay.name = "is_stay"
        return is_stay

    def set_is_stay(self, is_stay):
        self.df.loc[is_stay.index, "is_stay"] = is_stay

    def filter_abrupt_movements(self, abrupt_filt_size, abrupt_pctg_th):
        soft_stay = self.df.is_stay.rolling(
            abrupt_filt_size, min_periods=0, center=True
        ).mean()
        self.df.is_stay = soft_stay > abrupt_pctg_th

    def find_time_tags(self):
        toggle_indicator = self.df.is_stay.astype(int).diff()
        start_times = toggle_indicator[toggle_indicator == 1].index
        toggle_indicator = toggle_indicator.shift(-1)
        end_times = toggle_indicator[toggle_indicator == -1].index
        return start_times, end_times
