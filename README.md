# ReleaseManagment
Repository for release management tools and scripts

## Setup Github permssions

To be able to communicate to the Github server through their REST API,
You'll need to create a personal OAuth Token.

To create the access token:

1. Go to your 'Profile' page on Github
1. Click you profile icon in the top right corner and select "Settings"
1. From the list of settings, select "Personal access tokens"
1. Click the "Generate new token" button in the right hand corner.
1. Add the text "Release Managment" for the token description.
1. Select the top level "repo' permissions under "Select scopes".
1. Click "Generate token" on the bottom

The after this is completed, you will be presented with the access token.
Make sure you save this somewhere safe, it will not be shown to you again.
Since we will be using it in our scripts, you will need to export it as
an environment variable in your `.bashrc` or `.zshrc` file as shown below.

```sh
export GITHUB_OAUTH_TOKEN=<OAUTH_TOKEN>
```

Now all you will need to do is create a new shell and you should be able to access the server
with your new token.

You can find information on to use the Github REST API [here](https://developer.github.com/v3/)

## Testing

```
# Create release 2.2.0
$ ./bin/clemency.sh -o create -u kkirkup -t release -n 2.2.0 ~/repos/release-management-testing

# Finish release 2.2.0
$ ./bin/clemency.sh -o finish -u kkirkup -t release -n 2.2.0 -f $(pwd)/release_notes.txt ~/repos/release-management-testing
```


