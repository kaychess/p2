if echo 'foo: bar' | npx commitlint ; then
    echo "Command succeeded"
else
    echo "Command failed"
fi
