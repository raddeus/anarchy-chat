defmodule WebsocketPlayground.Schemas.Message do
  use Ecto.Schema

  @primary_key {:uuid, :binary_id, autogenerate: true}
  @derive {Jason.Encoder, except: [:__meta__, :__struct__]}

  schema "messages" do
    field :room, :string
    field :sender, :string
    field :content, :string

    timestamps()
  end
end
