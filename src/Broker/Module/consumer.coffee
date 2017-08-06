'use strict'

exports.put = (request, resource) ->
  queueId = +request.data.queueId
  name = request.body.name
  if !Number.isInteger(queueId) or queueId < 0
    return resource.status(500).json(
      status: 'error'
      error: 'queue_id:must_be_positive_integer')
  queue = queueManager[queueId]
  if typeof queue != 'object'
    return resource.status(500).json(
      status: 'error'
      error: 'queue:not_found')
  if ! typeof name == 'string'
    return resource.status(500).json(
      status: 'error'
      error: 'name:must_be_string')
  if typeof queueManager[queueId] == 'object'
    queueManager[queueId].name = name
    return resource.status(200).json(status: 'ok')
  return

exports.get = (request, resource) ->
  queueId = request.data.queueId
  if !Number.isInteger(queueId) or queueId < 0
    return resource.status(500).json(
      status: 'error'
      error: 'queueId:must_be_positive')
  queue = queueManager[queueId]
  if typeof queue != 'object'
    return resource.status(404).json(
      status: 'error'
      error: 'queue:not_found')
  consumers = queue.consumers.filter((consumer) ->
    consumer != null
  ).map((consumer) ->
    consumer.queue_id = queueId
    consumer
  )
  resource.status(200).json consumers

exports.delete = (request, resource) ->
  queueId = +request.data.queueId
  if !Number.isInteger(queueId) or queueId < 0
    return resource.status(500).json(
      status: 'error'
      error: 'queueId:must_be_positive')
  queue = queueManager[queueId]
  if typeof queue != 'object'
    return resource.status(500).json(
      status: 'error'
      error: 'queue:not_found')
  consumerId = +request.data.consumer_id
  if !Number.isInteger(consumerId) or consumerId < 0
    return resource.status(500).json(
      status: 'error'
      error: 'consumer_id:must_be_positive_integer')
  if typeof queue.consumers[consumerId] != 'object'
    return resource.status(500).json(
      status: 'error'
      error: 'consumer:not_found')
  delete queue.consumers[consumerId]
  resource.status(200).json status: 'ok'