'''

'''
import unittest
import os

import mc_tools.log as core

PATH = os.path.dirname(__file__)


class ReaderClassTests(unittest.TestCase):

    def setUp(self):
        self.filePath = os.path.join(PATH, 'data/multiplayer.log')
        
    def test_readLog_textFile(self):
        content = core.readLog(self.filePath)
        assert len(content) == 88
        
    def test_readLog_gzFile(self):
        content = core.readLog(self.filePath)
        assert len(content) == 88
        
    def test_readLog_otherFile(self):
        content = core.readLog(os.path.join(PATH, 'data/other.dat'))
        assert content == []
        
    def test_readLog_invalidFile(self):
        content= core.readLog('X:/invalid/test.jpg')
        assert content == []
        
    def test_findChat_textFileData(self):
        content = core.readLog(self.filePath)
        chat = core.findChatByUser(content, ['ooklah'])
        assert (chat[0] == "[22:12:29] [Server thread/INFO]: <ooklah> that took forever"), chat[0]
        assert len(chat) == 7
        
    def test_findChat_textFile(self):
        chat = core.findChatByUser(self.filePath, ['ooklah'])
        assert chat[0] == "[22:12:29] [Server thread/INFO]: <ooklah> that took forever"
        assert len(chat) == 7
        
    def test_findChat_textFileData_MultipleUsers(self):
        content = core.readLog(self.filePath)
        chat = core.findChatByUser(content, ['ooklah', 'Tailbones'])
        assert (chat[0] == "[22:11:33] [Server thread/INFO]: <Tailbones> that comes out to 3 chests full of gold nuggets"), chat[0]
        assert len(chat) == 15, len(chat)
        
    def test_getAllChat_textFile(self):
        content = core.readLog(self.filePath)
        chat = core.getAllChat(content)
        assert (chat[0] == "[22:11:33] [Server thread/INFO]: <Tailbones> that comes out to 3 chests full of gold nuggets"), chat[0]
        assert len(chat) == 15, len(chat)
        
    def test_findLine_MultiLines(self):
        content = core.readLog(self.filePath)
        lines = core.findLine(content, "joined the game")
        assert lines[0] == '[15:09:59] [Server thread/INFO]: ooklah joined the game'
        
    def test_findLine_SingleLine(self):
        content = core.readLog(self.filePath)
        lines = core.findLine([content[26]], "joined the game")
        assert lines[0] == '[15:09:59] [Server thread/INFO]: ooklah joined the game', lines
        
    def test_getSessions(self):
        content = core.readLog(self.filePath)
        sessions = core.getSessions(content)
        assert sessions[0].player == 'ooklah', sessions[0].player
        assert sessions[0].timeIn == '15:09:59', sessions[0].timeIn
        assert sessions[0].timeOut == '15:24:30', sessions[0].timeOut
        for s in sessions:
            assert s.loggedIn == False
            
    def test_getSessions_NoLogouts(self):
        content = core.readLog(os.path.join(PATH, "data/singleplayer.log"))
        sessions = core.getSessions(content)
        assert sessions[0].player == 'ooklah', sessions[0].player
        assert sessions[0].loggedIn == False
        
    def test_getSessions_MultiDay(self):
        '''
        Tests sessions that run between multiple log files.
        IE: over midnight and the log file changed
        '''
        content = core.readLog(os.path.join(PATH, "data/server/2014-02-07-2.log.gz"))
        sessions = core.getSessions(content)
        online = []
        for s in sessions:
            if s.loggedIn:
                online.append(s)
        
        assert len(online) == 3, len(online)
        
        content = core.readLog(os.path.join(PATH, "data/server/2014-02-08-1.log.gz"))
        sessions = core.getSessions(content, online)
        for s in sessions:
#            print s.player, s.timeOut
            assert s.loggedIn == False
            
    def test_Parsing_findFiles(self):
        parser = core.Parse(os.path.join(PATH, "data/server"))
        parser.findFiles()
        assert len(parser.files) == 202
        
    def test_Parsing_findSessions(self):
        parser = core.Parse(os.path.join(PATH, "data/server"))
        parser.findFiles()
        parser.findSessions()
        assert len(parser.sessions) == 927, len(parser.sessions)
        print parser.sessions[0]
            
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()