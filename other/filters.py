'''
collection of custom filters used in minecraft-overviewer
'''

def getCoords(poi):
    '''
    Extract the coords from the poi and returns a string, seperated by commas.
    '''
    try:
        return "{0}, {1}, {2}".format(poi['x'], poi['y'], poi['z'])
    except KeyError:
        return ", ".join( str(int(x)) for x in poi['Pos'] )


def getText(poi, pos=[1,2,3,4]):
    '''
    Gets the Text from all four lines on a sign.
    Returns a list.
    '''
    lines = []
    text = ['Text1', 'Text2', 'Text3', 'Text4']
    for p in pos:
        try:
                lines.append(poi[text[p-1]])
        except KeyError:
                print "Must use 1 - 4 in the positions"
    return lines

# Currently extra defs must be added to the globals
globals()['getText'] = getText
globals()['getCoords'] = getCoords

def playerIcons(poi):
    '''
    Finds a player skin and sets that as the icon.
    '''
    if poi['id'] == 'Player':
        poi['icon'] = "http://overviewer.org/avatar/%s" % poi['EntityId']
        return "Clocktower Reports last known location for %s" % poi['EntityId']


def signFilter(poi):
    '''
    Filter information signs. Signs that are not marking special things.
    Removes the ~ from the first line.
    '''
    if poi['id'] == 'Sign':
        text = getText(poi)
        if text[0].count("~") > 0:
            text[0] = text[0].replace("~", "")
            return "\n".join(l for l in text)


def spawnersFoundFilter(poi):
    '''
    Finds signs that are marked with '(ms)' in the first line
    (ms) - mob spawner
    First line is then excluded
    There is no way to determine if a spawner is found or not, so this relies on people marking it.
    '''
    if poi['id'] == 'Sign':
        text = getText(poi)
        if text[0].lower().count("(ms)") > 0:
            line = text[1]
            pos = getCoords(poi)
            return "{0} Spawner \n < {1} >".format(line, pos)


def portalFilter(poi):
    '''
    Find signs marked as portals.
    Currently no way to get portal data from overviewer.
    '''
    if poi['id'] == 'Sign':
        if poi['Text1'].count("(portal)") > 0:
            lines = getText(poi, [2,3,4])
            text = "\n".join([l for l in lines if l != ""])
            return "Portal\n{0}".format(text)



def horsesTamedFilter(poi):
    '''
    Finds tamed Horses, Donkeys or Mules.
    Returns the tamers name and if the animal has been named.
    '''
    if poi['id'] == 'EntityHorse':
        if poi['Tame']:
            horse = "Unknown"
            if poi['Type'] == 0:
                    horse = "Horse"
            if poi['Type'] == 1:
                    horse = "Donkey"
            if poi['Type'] == 2:
                    horse = "Mule"
            return "%s's %s %s" %( poi['OwnerName'], horse,  poi['CustomName'])


def eggZombieFilter(poi):
    '''
    Checks for Zombies that are holding eggs.
    Returns their location, for immediately elimination.
    '''
    if poi['id'] == 'Zombie':
        try:
            if  poi['Equipment'][0]['id'] == 344:
                return "Egg Zombie\n < %s >" %getCoords(poi)
        except KeyError, e:
            pass


def spawnersFilter(poi):
    '''
    Find all mob spawners in the world.
    Marks them with the type of mob and location.
    '''
    if poi['id'] == 'MobSpawner':
        return "\n".join([poi['EntityId'], "< %s>" %getCoords(poi)])