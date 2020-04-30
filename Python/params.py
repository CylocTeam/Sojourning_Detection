import numpy as np
import pandas as pd


class Params:
    def __init__(self, params_init):
        self.max_time_gap_pctl = params_init["max_time_gap_pctl"]
        self.ecdf_diff_th = params_init["ecdf_diff_th"]
        self.var_th = params_init["var_th"]
        self.abrupt_pctg_th = params_init["abrupt_pctg_th"]

        self.max_time_gap = np.array(
            np.round(params_init["max_time_gap_msec"]), dtype="timedelta64[ms]"
        )
        self.win_size = np.array(
            np.round(params_init["win_size_sec"]), dtype="timedelta64[s]"
        )
        self.abrupt_filt_const = np.array(
            np.round(params_init["abrupt_filt_const_sec"]), dtype="timedelta64[s]"
        )
        self.min_stay_duration = np.array(
            np.round(params_init["min_stay_duration_m"]), dtype="timedelta64[m]"
        )
        self.max_section_gap = np.array(
            np.round(params_init["max_section_gap_m"]), dtype="timedelta64[m]"
        )

        self._MAX_HIST_BINS = int(1e4)
        self._fs = 0

        self.win_size_smp = 0
        self.abrupt_filt_size = 0

    def _set_avg_sample_rate(self, time_diffs):
        self.fs = (
            time_diffs.where(
                time_diffs
                <= np.percentile(
                    time_diffs[time_diffs.notnull()], self.max_time_gap_pctl
                )
            )
            .map(lambda x: 1e9 / x)
            .mean()
        )

    def convert_filters_sec2smp(self, time_diffs):
        self._set_avg_sample_rate(time_diffs)
        sec2smp = lambda sec: np.floor(sec * self.fs).astype("int")
        self.win_size_smp = sec2smp(
            self.win_size.astype("timedelta64[s]").astype("float")
        )
        self.abrupt_filt_size = sec2smp(
            self.abrupt_filt_const.astype("timedelta64[s]").astype("float")
        )

    def set_var_th(self, acc_abs):
        acc_rollvar = acc_abs.rolling(self.win_size_smp, min_periods=0).var()
        hist, bin_edges = np.histogram(
            acc_rollvar[acc_rollvar.notnull()], bins=self._MAX_HIST_BINS
        )
        # normalize to pdf
        mvr_epdf = hist / sum(hist)
        knee_th = bin_edges[np.argwhere(mvr_epdf < self.ecdf_diff_th)[-1]]

        if not knee_th.size:
            return
        self.var_th = float(min([self.var_th, knee_th]))
