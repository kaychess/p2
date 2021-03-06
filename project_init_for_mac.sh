# For more details :

# Prompt
echo "

        Attention ::::::::::


        Script will remove following folders and files

        env/ node_modules/ .github/
        package.json package-lock.json
        commitlint.config.js
        .releaserc
        travis.yml

        Do you wish to proceed ?

        Input options  :  1 or 2
        "
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

# Sanitize
rm -rf env/ node_modules/ package.json package-lock.json commitlint.config.js
rm -rf commitlint.config.js travis.yml .releaserc .github/

nodeenv env

. env/bin/activate

# For editing package.json
npm install -g json

# Initiating node
npm init -y

# install commitlint
npm install --save-dev @commitlint/cli

# install Husky
npm install --save-dev husky

# install commitizen
npm install --save-dev commitizen

# install commitiquette
# Used to make commitizen use commitlint
# configurations.
npm install commitiquette  --save-dev

# Configuring Package.json
# For Husky hooks
json -I -f package.json -e "this.husky= {
    'hooks' : {
      'prepare-commit-msg': 'exec < /dev/tty && git cz --hook || true',
      'commit-msg': 'commitlint -E HUSKY_GIT_PARAMS'
      }
    }"

json -I -f package.json -e "this.config= {'commitizen': {'path': 'commitiquette'}}"

# install Angular Commit Conventions for commit lint
npm install --save-dev @commitlint/config-conventional
# setup the commit lint config files with installed configurations
echo 'module.exports = {extends: ["@commitlint/config-conventional"],
rules: {"body-max-line-length": [1, "always", 150],},
};' > commitlint.config.js

touch travis.yml

# Add commit-lint testing to travis builds
echo "
# travis.yml
matrix:
  include:
    - language: node_js
      node_js:
        - node
      script:
        - npm install --save-dev
        - commitlint-travis
    # Other Travis jobs goes here.
" > travis.yml

# Install semantic-release
npm install --save-dev semantic-release               \
    @semantic-release/changelog               \
    @semantic-release/commit-analyzer         \
    @semantic-release/exec                    \
    @semantic-release/git                     \
    @semantic-release/release-notes-generator

touch .releaserc
echo '
{
  "branch": "master",
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    [
      "@semantic-release/npm",
      {
        "npmPublish": false
      }
    ],
    [
      "@semantic-release/changelog",
      {
        "changelogFile": "CHANGELOG.md",
        "changelogTitle": "# Semantic Versioning Changelog"
      }
    ],
    [
      "@semantic-release/git",
      {
        "assets": [
          "CHANGELOG.md"
        ]
      }
    ],
    [
      "@semantic-release/github",
      {
        "assets": [
          {
            "path": "dist/**"
          }
        ]
      }
    ]
  ]
}
' > .releaserc

mkdir -p .github/workflows/
touch .github/workflows/release.yml

echo '
name: Release
on:
  push:
    branches:
      - master
jobs:
  release:
    name: Release
    runs-on: ubuntu-18.04
    steps:
      - name: Checkout
        uses: actions/checkout@v1
      - name: Setup Node.js
        uses: actions/setup-node@v1
        with:
          node-version: 12
      - name: Get Last committed message and check against commit lint
        run: git log -1 --pretty=%B | npx commitlint
      - name: Check if there is any error
        if: failure()
        run: |
          echo "::error ::  Error in Git Commit Message Lint "
          exit 1
      - name: Install Semantic Release dependencies
        run: npm ci
      - name: If needed generate Semantic versioning
        env:
          GITHUB_TOKEN: ${{ secrets.GH_PUBLIC_TOKEN }}
        run: npx semantic-release
  # lint:
  #   runs-on: ubuntu-latest
  #   env:
  #     GITHUB_TOKEN: ${{ secrets.GH_PUBLIC_TOKEN }}
  #   steps:
  #     - uses: actions/checkout@v2
  #       with:
  #         fetch-depth: 0
  #     - uses: actions/setup-node@v1
  #       with:
  #         node-version: 12
  #     - run: npm install
  #     - name: Add dependencies for commitlint action
  #       run: echo "::set-env name=NODE_PATH::$GITHUB_WORKSPACE/node_modules"
  #     - uses: wagoid/commitlint-github-action@v1
' > .github/workflows/release.yml

echo "

        Attention ::::::::::


        Remember you need to perform following steps
        a) Set Up GitHub actions tokens
        b) GitHub actions is configured with GH_PUBLIC_TOKEN change it as needed
        b) Travis CI permissions


"
