#!/usr/bin/env python3
"""Collect isolated Release launch timings without installing an XCTest runner."""
import argparse
import json
from pathlib import Path
import statistics
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--device', required=True)
parser.add_argument('--output', required=True, type=Path)
args = parser.parse_args()
results = {
    'method': 'Release -O, WEALTHY_LAUNCH_MEASUREMENT; isolated synthetic disk stores; one seed/warm-up then five warm launches without debugger. FirstFrame and HomeInteractive use in-app display callbacks from LedgerSession initialization, not OS process-start or injected-touch latency.',
    'sizes': {},
    'status': 'RUNNING',
}


def save():
    args.output.write_text(json.dumps(results, indent=2) + '\n')


def run(*command):
    return subprocess.run(['xcrun', 'devicectl', *command], check=True,
                          capture_output=True, text=True, timeout=45)


with tempfile.TemporaryDirectory(prefix='wealthy-c2a5-measure-', dir='/tmp') as directory:
    sample_path = Path(directory) / 'sample.json'

    def read_sample():
        run('device', 'copy', 'from', '--device', args.device,
            '--domain-type', 'appDataContainer', '--domain-identifier', 'com.harrison.Wealthy',
            '--source', 'tmp/Cycle2aLaunchMeasurement.json', '--destination', str(sample_path))
        return json.loads(sample_path.read_text())

    try:
        try:
            previous = read_sample().get('LaunchUptime')
        except (subprocess.CalledProcessError, FileNotFoundError):
            previous = None
        for count in (1000, 10000, 50000):
            row = results['sizes'][str(count)] = {'warmup': None, 'samples': []}
            for iteration in range(6):
                run('device', 'process', 'launch', '--device', args.device, '--terminate-existing',
                    'com.harrison.Wealthy', '--', '--cycle2a-performance', '--entry-count', str(count),
                    '-v4.language', 'en', '-v4.currency', 'JPY')
                deadline = time.monotonic() + 60
                while True:
                    try:
                        sample = read_sample()
                        if (sample.get('LaunchUptime') is not None and sample['LaunchUptime'] != previous
                                and sample.get('EntryCount') == count):
                            break
                    except (subprocess.CalledProcessError, FileNotFoundError):
                        pass
                    if time.monotonic() >= deadline:
                        raise RuntimeError('No fresh Home display-callback measurement within 60 seconds. Check the physical device unlock state, foreground app and actual Apple Intelligence availability; no data was read from the normal store.')
                    time.sleep(1)
                previous = sample['LaunchUptime']
                if iteration == 0:
                    row['warmup'] = sample
                else:
                    row['samples'].append(sample)
                    if len(row['samples']) == 5:
                        row['medians'] = {key: statistics.median(s[key] for s in row['samples'])
                                          for key in sample if key not in ('EntryCount', 'LaunchUptime')}
                save()
                print(f'{count} iteration {iteration}: FirstFrame={sample["FirstFrame"]:.6f}s HomeInteractive={sample["HomeInteractive"]:.6f}s', flush=True)
                if count == 10000 and iteration > 0 and sample['HomeInteractive'] > 2:
                    results['status'] = 'STOPPED_10K_OVER_2_SECONDS'
                    save()
                    raise SystemExit(2)
        results['status'] = 'COMPLETED'
        save()
    except Exception as error:
        results['status'] = 'BLOCKED'
        # Publish only the error class and our own synthetic-measurement diagnostic.
        results['error'] = str(error) if isinstance(error, RuntimeError) else type(error).__name__
        if isinstance(error, subprocess.CalledProcessError):
            # Keep the full native error in the local run log, outside the repository.
            print(error.stdout, error.stderr, flush=True)
        save()
        raise
