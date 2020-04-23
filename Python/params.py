import numpy as np
import pandas as pd


class Params:
    def __init__(self, params_init):
        self.win_size_sec = params_init["win_size_sec"]
        self.ecdf_diff_th = params_init["ecdf_diff_th"]
        self.var_th = params_init["var_th"]
        self.abrupt_filt_const_sec = params_init["abrupt_filt_const_sec"]
        self.min_stay_duration = params_init["min_stay_duration_m"]
        self.max_time_gap = params_init["max_time_gap_nsec"]
        self.max_section_gap = params_init["max_section_gap_m"]
        self.max_time_gap_pctl = params_init["max_time_gap_pctl"]

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
        self._fs = _set_avg_sample_rate(time_diffs)
        sec2smp = lambda sec: np.floor(sec * self.fs).astype("int")
        self.win_size_smp = sec2smp(self.win_size_sec)
        self.abrupt_filt_size = sec2smp(self.abrupt_filt_const_sec)

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


if __name__ == "__main__":
    pass
