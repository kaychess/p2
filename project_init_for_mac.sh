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
echo "module.exports = {extends: ['@commitlint/config-conventional']};" > commitlint.config.js

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
      - name: Install dependencies
        run: npm ci
      - name: Release
        env:
          GITHUB_TOKEN: ${{ secrets.SEMANTIC_RELEASE_SECRET }}
        run: npx semantic-release
' > .github/workflows/release.yml

echo "

        Attention ::::::::::


        Remember you need to configure
        a) GitHub actions tokens
        b) Travis CI permissions


"
