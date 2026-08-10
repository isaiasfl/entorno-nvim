from dataclasses import dataclass


@dataclass
class Student:
    name: str
    scores: list[float]


def average_score(scores: list[float]) -> float:
    return sum(scores) / len(scores)


def format_name(name: str) -> str:
    return name.strip().title()
