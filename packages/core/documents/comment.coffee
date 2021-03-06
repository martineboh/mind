class Comment extends share.UpvotableDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last activity on the comment
  # author:
  #   _id
  #   username
  #   avatar
  # discussion:
  #   _id
  #   status
  # body: the latest version of the body
  # bodyAttachments: list of
  #   _id
  # bodyMentions: list of
  #   _id
  # changes: list (the last list item is the most recent one) of changes
  #   updatedAt: timestamp of the change
  #   author: author of the change
  #     _id
  #     username
  #     avatar
  #   body
  # upvotes: list of
  #   createdAt: timestamp of the upvote
  #   author: author of the upvote
  #     _id
  # upvotesCount

  @Meta
    name: 'Comment'
    fields: (fields) =>
      _.extend fields,
        # We override this field with one with a reverse field.
        discussion: @ReferenceField Discussion, ['status'], true, 'comments', []

if Meteor.isServer
  Comment.Meta.collection._ensureIndex
    createdAt: 1

  Comment.Meta.collection._ensureIndex
    updatedAt: 1

  Comment.Meta.collection._ensureIndex
    lastActivity: 1

  Comment.Meta.collection._ensureIndex
    upvotesCount: 1
