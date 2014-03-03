'''

'''
import gzip
import os
import re

from mc_tools.data import Session

def readLog(fyle):
    '''
    Read either a log file or a .gz zipped log file.
    returns a list of all lines found in log files
    '''
    # Content is empty and then attempt to fill it
    content = None
    
    if os.path.splitext(fyle)[-1] == ".log":
        f = open(fyle, 'r')
        content = f.readlines()
        f.close()
    
    if os.path.splitext(fyle)[-1] == ".gz":
        f = gzip.open(fyle, 'rb')
        content = f.readlines()
        f.close()
        
    # Strip off the line returns, they arn't needed
    cleaned = []
    if content != None:
        for line in content:
            cleaned.append(line.rstrip())
        
    return cleaned

def getDate(filepath):
    '''
    Return the date of the filename.
    '''
    results = re.search(r'(\d{4}-\d{2}-\d{2})', filepath)
    if results:
        return results.group(1)
    
def sortLog(data):
    '''
    Sort the data into different groups based on what
    kind of info is given.
    '''
    pass

def _searchChat(data, search):
    '''
    regex search for chat lines: [HH:MM:SS] [Server thread/INFO] <player>
    '''
    chat = []
    for line in data:
        if re.search((r'\[\d{2}:\d{2}:\d{2}\]'
                      ' \[Server thread/INFO\]:'
                      ' <%s>')% "|".join(search), line):
            chat.append(line)
    return chat
        
def getAllChat(data):
    '''
    Find and return all the chat dialog by players.
    '''
    # Check if we have is a string, send it to get read first.
    if isinstance(data, str):
        data = readLog(data)

    return _searchChat(data, ['\w+'])

def findChatByUser(data, users):
    '''
    Find the chat lines in the data. Give users as a list.
    '''
    # Check if we have is a string, send it to get read first.
    if isinstance(data, str):
        data = readLog(data)
    
    return _searchChat(data, users)

def findLine(data, value):
    '''
    Find a line that contains a particular value.
    '''
    # Check if we have is a string, send it to get read first.
    if isinstance(data, str):
        data = readLog(data)
        
    lines = []
    for line in data:
        if re.search(value, line):
            lines.append(line)
            
    return lines

def getSessions(data, sessions = []):
    '''
    Get the the login/logout sessions for each player.
    '''
    # New list because it can remember items between calls
    sessions = list(sessions)
    login = "logged in with entity id"
    logout = "left the game"
    # Find the login data
    for i in range(len(data)):
        
        # Find the login data
        if findLine([data[i]], login):
            session = Session.Session(data[i])
            session.player = data[i+1]
            sessions.append(session)
            continue
            
        # Find the logout data
        if findLine([data[i]], logout):
            # Pull the player name from the line
            player = re.findall(r'\b(\w+)\b %s' %logout, data[i])[0]
            # Find the first session where the players match and they are 
            # logged in. 
            for s in sessions:
                if s.player == player and s.loggedIn == True:
                    s.logout(data[i])
            continue
            
        # Find the server shutdown if nothing else.
        if findLine([data[i]], "Stopping server"):
            for s in sessions:
                if s.loggedIn == True:
                    s.logout(data[i])
                    
    return sessions

class Parse(object):
    def __init__(self, path):
        self._extInclude = [".log", ".gz"]
        self._path = path
        self._files = []
        self._sessions = []
        
        # Caching flags
        self._cFiles = False
        self._cSession = False
        
    def findFiles(self):
        if self._cFiles:
            return
        
        self._files = [f for f in os.listdir(self._path)
                       if any([f.endswith(ext) for ext in self._extInclude])]
        self._cache = True
            
    def findSessions(self):
        '''
        Find all the sessions from the log files processed.
        '''
        # Stores sessions that havn't logged out yet while looking at the 
        # next day
        temps = []
        
        if self._cSession:
            return
        
        for date, content in self.iterFiles():
            sessions = getSessions(content, temps)
            # Clear out temps before adding new sessions to it.
            temps = []
            
            for s in sessions:
                # If the session is logged out
                if s.loggedIn is False:
                    # check to make sure the date hasn't already been filled.
                    # from a session in temps
                    if s.dateIn == "":
                        s.dateIn = date
                    s.dateOut = date
                    self._sessions.append(s)
                # If the session is still logged in, save it for the next file
                # to parse.
                else:
                    s.dateIn = date
                    temps.append(s)
        # The sessions are cached, and don't need to be run again
        self._cSession = True
        
    @property
    def files(self):
        '''
        Get the file file names without path
        '''
        return self._files
    
    @property
    def sessions(self):
        '''
        Get the sessions from the files read.
        '''
        return self._sessions
    
    def clearCache(self):
        self._cFiles = False
        self._cSession = False
        
    def setExtensions(self, exts):
        '''
        Extensions to use for parsing.
        Defaults are [".log", ".gz"]
        '''
        self._extInclude = exts
        
    def getExtensions(self):
        return self._extInclude
    
    def iterFiles(self):
        '''
        Returns the date of the file and the content of the file
        (date, content)
        '''
        for f in self._files:
            date = getDate(f)
            content = readLog(os.path.join(self._path, f))
            yield(date, content)
        