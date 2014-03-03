'''

'''
import unittest
import os

from mc_tools.data.Session import Session

PATH = os.path.dirname(__file__)

class Test(unittest.TestCase):


    def setUp(self):
#        self.filePath = os.path.join(PATH, 'data/2014-01-24-4.log')
#        self.content = core.readLog(self.filePath)
        pass

    def tearDown(self):
        pass


    def test_getDate_Pass(self):
        session = Session('[15:09:59] [Server thread/INFO]: ooklah joined the game')
        assert session.timeIn == '15:09:59', session.timeIn
        
    def test_getPlayer_Pass(self):
        session = Session('[15:09:59] [Server thread/INFO]: ooklah joined the game')
        session.player = '[15:09:59] [Server thread/INFO]: ooklah joined the game'
        assert session.player == 'ooklah', session.player

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()