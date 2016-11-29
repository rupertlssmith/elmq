### Message Queues for Elm

Elmq provides a way to send and receive messages over named channels.

A message can be sent, resulting in a Cmd to Elm. A message can be received by
forming a subscription on a channel.


## Examples:

This example shows how to set up a channel named "chat.elm" and to send and
receive string messages over that channel:

    import Elmq

    -- To send string messages to the "chat.elm" channel.
    elmTalk : String -> Cmd msg
    elmTalk message =
        Elmq.sendString "chat.elm" message

    -- To receive string message on the "chat.elm" channel
    type Msg =
        ReceiveChat String

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Elmq.listenString "chat.elm" ReceiveChat

## Future direction:

A general purpose asynchronous messaging feature might be a welcome addition to
Elm. Here are some suggestions on future directions this work could take:

If two listeners are on the same channel to they both get all the messages
(pub/sub style), or does each listener get each message uniquely (point-to-point
style). Would likely want to support both models.

Should there be some significance to the channel names when subscribing? For
example if channels are named with dot notation like newsgroups "comp.lang.elm",
then can you create subscriptions spanning multiple channels like "comp.lang.*"?

When the type of data sent to a channel does not match the expected type being
listened for, a default value is passed instead. Could there be a better way,
which would be to not trigger a listener event at all when this happens?
