defmodule WebsocketPlayground.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :room, :string
      add :sender, :string
      add :content, :text
      timestamps()
    end
    create index(:messages, [:room], comment: "Room Index")
  end
end
