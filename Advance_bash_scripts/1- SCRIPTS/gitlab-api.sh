#!/bin/bash
GITLAB_API_KEY=

#valid access levels.
10 => Guest access
20 => Reporter access
30 => Developer access
40 => Maintainer access
50 => Owner access # Only valid for groups

# 'user-id', 'access-level'
U1=( '2' '')

# Add a member to a group or project 
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --data "user_id=1&access_level=30" https://gitlab.example.com/api/v4/groups/:id/members
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --data "user_id=1&access_level=30" https://gitlab.example.com/api/v4/projects/:id/members
