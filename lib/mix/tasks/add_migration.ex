defmodule Mix.Tasks.TzWorld.Gen.Migration do
  @moduledoc """
  This task generates a migration that will create the table needed by
  `TzWorld.TimezoneGeometry`.


  ```elixir
  defmodule MyApp.Repo.Migrations.AddTimezoneGeometries
    use Ecto.Migration
    def up do
      execute "CREATE EXTENSION IF NOT EXISTS postgis"
      create table(:timezone_geometries) do
        add :timezone, :string, null: false
      end
      execute "ALTER TABLE timezone_geometries ADD COLUMN geometry geometry NOT NULL"
      unique_index(:timezone_geometries, :timezone)
    end

    def down do
      drop table(:timezone_geometries)
    end
  end
  ```
  """

  use Mix.Task

  import Mix.Generator
  import Mix.Ecto

  @migration_name "AddTimezoneGeometries"
  @shortdoc "Generates a migration to create the `timezone_geometries` table"

  @doc false
  def run(args) do
    path = "#{Mix.Project.app_path}/priv/repo/migrations/"
    repo = parse_repo(args) |> hd
    filename = "#{timestamp()}_add_timezone_geometries.exs"
    file = Path.join(path, filename)
    create_directory path
    create_file file, migration_template(mod:
                        Module.concat([repo, Migrations, @migration_name]))
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)

  embed_template :migration, """
  defmodule <%= inspect @mod %> do
    use Ecto.Migration
    def up do
      execute "CREATE EXTENSION IF NOT EXISTS postgis"
      create table(:timezone_geometries) do
        add :timezone, :string, null: false
      end
      execute "ALTER TABLE timezone_geometries ADD COLUMN geometry geometry NOT NULL"
      unique_index(:timezone_geometries, :timezone)
    end

    def down do
      drop table(:timezone_geometries)
    end
  end
  """
end
