import os.path
import unittest

def all_tests():
    return unittest.TestLoader().discover(os.path.dirname(__file__))
