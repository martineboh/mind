class UploadStatus
  constructor: (@documentId, @filename) ->
    # Current status or error message displayed to user.
    @status = new ReactiveField null
    # Progress of reading from file, in %.
    @readProgress = new ReactiveField 0
    # Progress of uploading file, in %.
    @uploadProgress = new ReactiveField 0

    @done = new ReactiveField false
    @error = new ReactiveField null

  # Fake update method for compatibility with MeteorFile.
  update: (id, modifier) ->
    @status modifier.$set.status
    @readProgress modifier.$set.readProgress
    @uploadProgress modifier.$set.uploadProgress

class StorageFile extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # author:
  #   _id
  # filename: filename under which the file is stored
  # originalFilename: user's provided filename
  # mimeType: user's provided MIME type
  # size: user's provided size
  # done: true or false, has the file been successfully uploaded
  # active: true or false, once we set a file to active, we should never set it back to false
  #         because it means that it is used somewhere; even if user removes it from content
  #         the file is needed for history/old version of the content; as a consequence
  #         files which were once set to active should not be removed ever (or at least very
  #         careful check should be done that they are really not referenced anywhere, even
  #         not in old versions of content)

  @Meta
    name: 'StorageFile'
    fields: =>
      # Files can be reused across content by copying content over, so if author
      # is deleted we do not want also file document to be deleted.
      author: @ReferenceField User, [], false
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['status', 'readProgress', 'uploadProgress'], true
      removeFile: @Trigger ['filename'], (document, oldDocument) =>
        return if document

        assert oldDocument

        Storage.remove oldDocument.filename

  @UPLOAD_CHUNK_SIZE = 128 * 1024 # bytes

  @uploadFile: (file, callback) ->
    Meteor.call 'StorageFile.new',
      name: file.name
      type: file.type
      size: file.size
    ,
      (error, {documentId, filename}) =>
        return callback error if error

        uploadStatus = new UploadStatus documentId, filename

        meteorFile = new MeteorFile file,
          collection: uploadStatus

        meteorFile.upload file, 'StorageFile.upload',
          documentId: documentId
          size: @UPLOAD_CHUNK_SIZE
        ,
          (error) =>
            if error
              uploadStatus.status "#{error}"
              uploadStatus.error error
              return

            uploadStatus.done true

        callback null, uploadStatus

if Meteor.isServer
  StorageFile.Meta.collection._ensureIndex
    createdAt: 1

  StorageFile.Meta.collection._ensureIndex
    updatedAt: 1
