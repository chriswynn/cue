defmodule Cue.Repo.Migrations.CreateCuesTables do
  use Ecto.Migration

  def change do
    create table(:cues) do
      add :name, :string, null: false
      add :description, :string
      add :creator_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:cues, [:name])
    create index(:cues, [:creator_id])

    create table(:user_cues) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :cue_id, references(:cues, on_delete: :delete_all), null: false
      add :role, :string, default: "member"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_cues, [:user_id, :cue_id])
    create index(:user_cues, [:user_id])
    create index(:user_cues, [:cue_id])
  end
end
