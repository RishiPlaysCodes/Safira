"""Starter script for future custom object-detection training.

This file intentionally stays lightweight until a real labeled dataset is added.
It documents the expected inputs/outputs so training can be wired later without
changing the mobile/backend architecture.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DATASETS = {
    'helmet': ROOT / 'datasets' / 'helmet',
    'red_light': ROOT / 'datasets' / 'red_light',
    'vehicles': ROOT / 'datasets' / 'vehicles',
}
EXPORTS = {
    'helmet': ROOT.parent / 'mobile' / 'assets' / 'models' / 'helmet_detector.tflite',
    'red_light': ROOT.parent / 'mobile' / 'assets' / 'models' / 'red_light_detector.tflite',
    'vehicles': ROOT.parent / 'mobile' / 'assets' / 'models' / 'vehicle_detector.tflite',
}


def describe_plan() -> None:
    for name, dataset in DATASETS.items():
        print(f'{name}: dataset={dataset} -> export={EXPORTS[name]}')


if __name__ == '__main__':
    describe_plan()
