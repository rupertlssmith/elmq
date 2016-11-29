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
