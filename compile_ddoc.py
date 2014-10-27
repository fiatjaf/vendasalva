import sys
import json
from couchapp.localdoc import document

print json.dumps(document(sys.argv[1]).doc())
