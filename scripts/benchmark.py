"""Summarize captured frame times; never generates benchmark observations."""
import argparse
import csv
import json
import math
import statistics

def summarize(values):
    if not values or any(not math.isfinite(x) or x<=0 for x in values):
        raise ValueError('frametime_ms must contain finite positive measurements')
    slowest=sorted(values,reverse=True)[:max(1,math.ceil(len(values)*0.01))]
    return {'frames':len(values),'duration_s':sum(values)/1000,
            'average_fps':1000/statistics.fmean(values),
            'one_percent_low_fps':1000/statistics.fmean(slowest),
            'one_percent_low_definition':'reciprocal mean of slowest ceil(1% of frames)'}

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('csv_file')
    args=parser.parse_args()
    with open(args.csv_file,newline='') as f:
        values=[float(row['frametime_ms']) for row in csv.DictReader(f)]
    print(json.dumps(summarize(values),indent=2))
