store = require './store'

module.exports.sync = sync = (force=false) ->
  lastSync = localStorage.getItem 'lastSync'
  if force or not lastSync or parseInt(lastSync) + 3600 < parseInt(Date.now()/1000)
    # sync once an hour
    localStorage.setItem 'lastSync', parseInt(Date.now()/1000)
    couchURL = localStorage.getItem 'remoteCouch'
    if not couchURL
      console.log 'no couchURL, will not sync'
      return
    console.log 'got couchURL from localStorage, will sync: ' + couchURL
    syncing = store.sync(couchURL)
    console.log 'replication started'
    syncing.on 'change', (info) -> console.log 'change', info
    syncing.on 'error', (info) -> console.log 'error', info
    syncing.on 'complete', (info) ->
      console.log 'replication complete', info

module.exports.getRemoteCouch = getRemoteCouch = ->
  # set callback to be called by the popup window
  window.passDB = (couchURL) ->
    # when called, this callback will save the remote couch url
    # so it can later be used by our automatic sync process
    console.log('got couchdb url from popup: ' + couchURL)
    localStorage.setItem('remoteCouch', couchURL)
    opened.close()
    sync()

  # open the popup
  opened = window.open(
    '/popup.html',
    '_blank',
    'height=400, width=550'
  )

