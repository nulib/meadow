defmodule Meadow.NotificationTest do
  use ExUnit.Case, async: true
  alias Meadow.Notification
  doctest Meadow.Notification

  @job_id "job:01DGFPKRV7QQ3CABVCYE3K1GHX"
  @payload ~w(list of words)
  @pubsub Meadow.PubSub

  setup do
    @job_id |> Notification.clear!()
    :ok
  end

  test "creates storage" do
    assert(%Ets.Set{} = Notification.init(@job_id))
  end

  test "notifies on update" do
    Phoenix.PubSub.subscribe(@pubsub, @job_id)

    @job_id |> Notification.update({:test})

    assert_received %Phoenix.Socket.Broadcast{
      event: "update",
      payload: %{id: [:test], object: %Meadow.Notification{status: "pending"}},
      topic: @job_id
    }
  end

  test "persists updates" do
    Phoenix.PubSub.subscribe(@pubsub, @job_id)

    @job_id
    |> Notification.update({:test}, %{status: "pass", content: @payload})

    assert_received %Phoenix.Socket.Broadcast{
      event: "update",
      payload: %{
        id: [:test],
        object: %Meadow.Notification{status: "pass", content: @payload}
      },
      topic: @job_id
    }

    assert(
      Notification.fetch(@job_id, {:test}) == %Meadow.Notification{
        status: "pass",
        content: @payload
      }
    )
  end

  test "dump" do
    Phoenix.PubSub.subscribe(@pubsub, @job_id)

    @job_id
    |> Notification.update({:test, 1})
    |> Notification.update({:test, 2}, %{status: "pass"})
    |> Notification.update({:test, 3}, %{status: "fail"})

    Phoenix.PubSub.subscribe(@pubsub, @job_id)
    @job_id |> Notification.dump()

    assert_received %Phoenix.Socket.Broadcast{
      event: "update",
      payload: %{
        id: [:test, 1],
        object: %Meadow.Notification{status: "pending"}
      },
      topic: @job_id
    }

    assert_received %Phoenix.Socket.Broadcast{
      event: "update",
      payload: %{
        id: [:test, 2],
        object: %Meadow.Notification{status: "pass"}
      },
      topic: @job_id
    }

    assert_received %Phoenix.Socket.Broadcast{
      event: "update",
      payload: %{
        id: [:test, 3],
        object: %Meadow.Notification{status: "fail"}
      },
      topic: @job_id
    }
  end
end
