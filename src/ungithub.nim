import std/asyncdispatch, std/httpclient, std/json, std/os
import github, rest

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

if getEnv("GITHUB_TOKEN") == "":
  echo "Create an API token at https://github.com/settings/tokens/new" &
    """ with "repo" and "user" permissions, then pass it in the shell environment""" &
    """ as GITHUB_TOKEN."""
  quit()
else:
  waitFor all(cleanseStars(), cleanseFollowing())
