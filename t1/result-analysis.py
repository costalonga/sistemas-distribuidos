import os
import sys

if __name__ == '__main__':
    result_dirs = ["v1", "v2"]
    curr_path = os.getcwd()
    times = {}
    for result_dir in result_dirs:
        result_dir_path = os.path.join(curr_path, result_dir)
        for file in os.listdir(result_dir_path):
            print(file)
            file_path = os.path.join(result_dir_path, file)
            with open(file_path, "r") as f:
                for time_mark in f.readlines():
                    t = round(float(time_mark[12:]),2)
                    times[file] = t


