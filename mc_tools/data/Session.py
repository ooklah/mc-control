'''

'''
import re

class Session(object):
    def __init__(self, loginLine = None):
            
        self._player = ""
        
        self._dateIn = ""
        self._timeIn = ""
        
        self._dateOut = ""
        self._timeOut = ""
        
        self._position = ""
        
        self._ip = ""
        self._port = ""
        
        # Assumes that when the session is created, the player is logged in
        # player stays logged in until a log out is given. Logouts may not
        # be found in a single log.
        self.loggedIn = True
        
        if loginLine:
            self.login(loginLine)
        
    def login(self, login):
        self._timeIn = self._getTime(login)
        # Find the word before joined the game and return that
        # 1.7 - 1.8 login line

    def logout(self, logout):
        self._timeOut = self._getTime(logout)
        self.loggedIn = False
    
    def meta(self, metaLine):
        '''
        Process the the meta line that contains the ip:port, entity id and 
        position of the player.
        '''
        pass
    
    def _getTime(self, line):
        # Find me the mc timestamp of [xx:xx:xx]
        # Next: verify that it's actually a time?
        search = re.search(r'^\[(\d{2}:\d{2}:\d{2})\]', line)
        if search:
            return search.group(1)
    
    @property
    def timeIn(self):
        return self._timeIn
    
    @property
    def timeOut(self):
        return self._timeOut
    
    def _setDateIn(self, date):
        self._dateIn = date
        
    def _setDateOut(self, date):
        self._dateOut = date
        
    def _getDateIn(self):
        return self._dateIn
    
    def _getDateOut(self):
        return self._dateOut
    
    dateIn = property(_getDateIn, _setDateIn)
    dateOut = property(_getDateOut, _setDateOut)
    
    def _getPlayer(self):
        return self._player
    
    def _setPlayer(self, line):
        try:
            self._player = re.findall(r'\b(\w+)\b joined the game', line)[0]
        except IndexError, e:
            print e
            print "Failed On: ", line, ("\nWhile looking "
                                        "for player's name on login")
        
    player = property(_getPlayer, _setPlayer)
    
    def __str__(self):
        return "%s: Login: %s %s Logout: %s %s" %(self.player,
                                                 self.dateIn,
                                                 self.timeIn,
                                                 self.dateOut,
                                                 self.timeOut)
    