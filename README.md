# sync-DBeaver-config

## Using this tool to sync configuration of DBeaver between different computers

- When you are running DBeaver and you have `multiple computer` or you just `reinstall
the OS` and lazy to `switch between different computer` to get the `DBeaver configuration`
file for all stored `DB connections`, `queries` and `configs`, don't worry, this tools will do that
boring part for you. Will make sure you can have your `own DBeaver configuration` same as
each computer you want.
- This tool have `two passwords protection layers` based on the `user inputted`, you can see sample
usage below.

## Prerequisites

- For MacOS and Linux running on `terminals`
- For Windows, running on `PowerShell` or sub `systems Linux`
- Must have [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) command installed
- Should set your `own github private repository` to contain your `DBeaver configuration` files
  - Even `the configuration` file are `encrypted` with your `own password`, but I think that `not safe` in `these days`.
- Create and replace your `new` `private github url repository` in file: .env
  - this .env file should be `created first` in `same location` as the `README.md` file.
  - with keyword: `GITHUB_REPOSITORY_URL`. Ex: `GITHUB_REPOSITORY_URL="https://github.com/henry0hai/henry0hai"`
  - make sure you have `your permissions` to `read/write` on that repository.

## Notes

- Just tested on `MacOS`
- Windows & Linux will `wait feedback` if you have some try (too lazy for that)

## Command

- For the `first time` you should run this tool `on computer` that `already have`
the `DBeaver configuration` and run `sync local first`.

- This one will `copy` your current `DBeaver configuration` and `create` the
`compressed file` to `upload` to `your repository` with your `encrypted password`.
  - `sh sync-config.sh --local-data <your-password>`

example:

```sh
sh sync-config.sh --local-data '123456' '456789'
```

- This one will sync from the `compressed files` that `on` the `github repository`,
and `extract` the configuration into the `DBeaver configuration` path depending on
each system `OS version` base on your `encrypted password` you created with param:
`--local-data` .
  - `sh sync-config.sh --remote-data <your-password>`

example:

```sh
sh sync-config.sh --remote-data '123456' '456789'
```

## Disclaimer

- Your `DBeaver configuration` should store on `private repositories` to `prevent leaking` or `cracking`
the configuration
- Should create `empty repositories` (new one) before using this tool, all `existing repositories` may
`be overwritten` and lead to `conflict`, `lost data`, etc.
- `Not all of the cases` are `covered`, please `create PR` if you have any `suggestions to make`.
  