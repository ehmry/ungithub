import std/asyncdispatch, std/httpclient, std/json, std/os, std/sequtils, std/xmltree
import github, rest

proc dumpFollowing() {.async.} =
  echo """<outline text="Following">"""
  for res in getUserFollowing.call().retried():
    let
      body = await res.body
      list = parseJson body
    var lastLogin = ""
    for follow in list.getElems:
      let login = follow["login"].getStr
      echo <>outline(
        text=login, type="rss",
        htmlUrl="https://github.com/" & login,
        xmlUrl="https://github.com/" & login & ".atom")
      if login == lastLogin: break
      lastLogin = login
    break
  echo """</outline>"""

proc dumpFollowers() {.async.} =
  echo """<outline text="Followers">"""
  for res in getUserFollowers.call().retried():
    let
      body = await res.body
      list = parseJson body
    var lastLogin = ""
    for follow in list.getElems:
      let login = follow["login"].getStr
      echo <>outline(
        text=login, type="rss",
        htmlUrl="https://github.com/" & login,
        xmlUrl="https://github.com/" & login & ".atom")
      if login == lastLogin: break
      lastLogin = login
    break
  echo """</outline>"""

proc cleanseStars() {.async.} =
  for res in getUserStarred.call().retried():
    let
      body = await res.body
      list = parseJson body
    for star in list.getElems:
      echo "unstarr ", star["full_name"].getStr
      for resp in deleteUserStarredOwnerRepo.call(
          repo=star["name"].getStr, owner=star["owner"]["login"].getStr).retried():
        asyncCheck res.body
        break

proc cleanseFollowing() {.async.} =
  for res in getUserFollowing.call().retried():
    let
      body = await res.body
      list = parseJson body
    for follow in list.getElems:
      let username = follow["login"].getStr
      echo "unfollow ", username
      for resp in deleteUserFollowingUsername.call(username).retried():
        asyncCheck res.body
        break

proc dumpHead() =
  echo <>head(<>title(newText "GitHub"))

if getEnv("GITHUB_TOKEN") == "":
  echo "Create an API token at https://github.com/settings/tokens/new" &
    """ with "repo" and "user" permissions, then pass it in the shell environment""" &
    """ as GITHUB_TOKEN."""
  quit()
else:
  #waitFor all(cleanseStars(), cleanseFollowing())

  echo """<?xml version="1.0" encoding="UTF-8"?>"""
  echo """<opml version="2.0">"""
  dumpHead()
  echo """<body>"""
  echo """<outline text="GitHub">"""
  waitFor dumpFollowing()
  waitFor dumpFollowers()
  echo """</outline>"""
  echo """</body>"""
  echo """</opml>"""
