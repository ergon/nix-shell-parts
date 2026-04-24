def escape: "\u001b";
def reset: "[0m";
def colors:
  {
    "cyan": "[1;36m",
    "magenta": "[1;35m",
    "yellow": "[1;33m",
    "green": "[1;32m",
    "red": "[1;31m",
  };

def colored_text(text; color):
  escape + colors[color] + text + escape + reset;

def render_updates:
  if (.updates | length > 0) then
    "Updates:\n" + (
      (.updates | sort_by(.updateType) | group_by(.updateType))
      | map(
          colored_text(.[0].updateType + ":"; "magenta") + "\n"
          + (map(
              " - " + .packageName
              + " [" + colored_text(.currentValue; "yellow")
              + " -> " + colored_text(.newValue; "green") + "]"
              + (if (.ageInDays != null or ((.homepage // "") | length) > 0) then
                  " ("
                  + (if .ageInDays != null then "age: " + (.ageInDays | tostring) + "d" else "" end)
                  + (if ((.homepage // "") | length) > 0 then (if .ageInDays != null then " - " else "" end) + .homepage else "" end)
                  + ")"
                else "" end)
              + (if ($showFiles) then "\n   - " + (.files | join("\n   - ")) else "" end)
            ) | join("\n"))
        )
      | join("\n\n")
      )
  else
    ""
  end;

def render_warnings:
  if (.warnings | length > 0) then
    (if (.updates | length > 0) then "\n\n" else "" end)
    + colored_text("Warnings:"; "red") + "\n"
    + (.warnings| map(
          " - " + .packageName + " [" + colored_text(.currentValue; "yellow") + "]" + " - " + (.warnings | map(.message) | join(" | "))
      ) | join("\n"))
  else
    ""
  end;

def render_manager:
  colored_text("Manager: "; "cyan") + (.manager | ascii_upcase) + "\n"
  + render_updates
  + render_warnings;

def extract_warnings:
  map(.deps[]?
    | select(.warnings and (.warnings | length > 0))
    | {
        packageName: .packageName,
        currentValue: .currentValue,
        warnings: .warnings
      }
  )
  | unique;

def extract_updates:
  map(
    . as $packageFile
    | $packageFile.deps[]?
      | select(.updates and (.updates | length > 0))
      | . as $dep
      | $dep.updates[]
      | {
          packageName: $dep.packageName,
          currentValue: $dep.currentValue,
          newValue: (.newVersion // .newDigest),
          ageInDays: .newVersionAgeInDays,
          updateType: .updateType,
          homepage: $dep.homepage,
          packageFile: $packageFile.packageFile
        }
  )
  | group_by(del(.packageFile))
  | map((.[0] | del(.packageFile)) + { files: (map(.packageFile) | unique) });

to_entries
| map({
    manager: .key,
    updates: (.value | extract_updates),
    warnings: (.value | extract_warnings)
  })
| map(select((.updates | length > 0) or (.warnings | length > 0)))
| map(render_manager)
| join("\n\n")