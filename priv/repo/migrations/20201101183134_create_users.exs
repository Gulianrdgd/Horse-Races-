defmodule Bussenv2.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :color, :string
      add :bet, :integer
      add :roomCode, :string
      add :username, :string

      timestamps()
    end

  end
end
