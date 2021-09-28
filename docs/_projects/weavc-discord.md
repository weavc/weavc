---
layout: md
title: weavc-discord
repo: weavc/weavc-discord
description: Javascript library of helpers for discord bots, helps with parsing and routing messages and paging embeds with reactions. Works inline with discord.js
tags: ['javascript', 'npm', 'typescript', 'discord']
sort_key: 2
pinned: false
---

{% include project-headers.html %}

There can be implemented alongside `discord.js` to provide a number of utilities includinga router, argument parser and embed pager. 

#### Router

The router is used to route incoming messages to different functions to handle the result. Using this is a nice setup from using large amounts of if statements to check and redirect the message. This works much like many http frameworks i.e. `expressjs`, where you setup your routes and when an incoming request comes in that matches the route it is passed to the function. 

The `Router` class takes a routes parameter, this is a list of routes you provide to the router that it uses to make routing decisions and might look like this:
```javascript
let routes : Route[] = [
    { name: 'prefix', alias: ['mogo', 'weavc'], children: [
        { name: 'welcome', alias: ['hello', 'hi', 'welcome'], handler: grettingsHandler },
        { name: 'github', alias: ['github', 'git'], handler: githubHandler },
        { name: 'code', alias: ['c', 'code'], args: codeArgs, handler: codeHandler, children: [
            { name: 'code-help', alias: ['help', '--help', '?'], handler: codeUsage, default: true },
        ] }
    ] }
]

let router = new Router(routes);
```

A `Route` consists of a number of fields and options:
- `name`: just a name to identify the route
- `alias`: an array of strings to match on
- `handler`: handler function, this is where the message is passed to if it matches the requirements
- `children`: an array of routes, if the parent route matches, the next part of the message will be checked against the children
- `args`: an array of `ArgParser`s, used to identify flags, arguments and values inside a message, these will be passed to the handler
- `default`: if no routes match, but there is a default child, this will be used without alias' matching

Once the `Router` class has been initialized you can pass incoming messages to it like so:
```javascript
client.on('message', (message: Message) => { router.Go(message) });
```

#### Args

There are a number of ways to parse arguments from a message in this library. It can be done through the router by passing through an array of `ArgParser`'s to the `args` field in a `Route`. This will pass a class to the handler that allows you to find values within a message.

```javascript
// define flags and values
// [default] gets the first parameter after the matching route. 
// [default] only works when parsing through the router & calling ParseArgs directly
let args : ArgParseOptions[] = [
    { name: 'type', flags: ['-t', '--type'], getValue: true },
    { name: '[default]', flags: [], getValue: true }
]

// add 'argOptions: args' to the route model
let routes : Route[] = [
    { name: 'test', alias: ['t', 'test'], argOptions: args, handler: handler }
    ...
]

let handler : RouteHandler = (message, client, args) => {
    // incoming message: 'test 'hello world' - t TYPE_1'

    let dVal = args.getValue('!default');
    let cVal = args.getValue('type');W

    // dVal: 'hello world'
    // cVal: 'TYPE_1'

    ...
}
```

There is also a method called `ParseArgs` exported. This takes the content of a message and an array of `ArgParser`'s, much like the router. It will return the same `ArgsModel` class as well.

#### Pager

A useful method that can be used to page through numerous embeds using ⬅ ➡ reactions. This is quite commonly used for help pages or when there is alot of data to display.

Its as simple as creating your embeds, do this using `discord.js`'s `MessageEmbed` class, then pass the message you are responding to, client and the array of embeds to the Pager method. there is also a number of options that can be passed though as well.

```javascript
let m1: MessageEmbed = new MessageEmbed()
    .setTitle('Page 1')
    .setColor(0xb5130f)
    .addField('test field', 'just a field for testing!')
    .setAuthor(client.user.username, client.user.avatarURL())
    .setTimestamp(new Date())

let m2: MessageEmbed = new MessageEmbed()
    .setTitle('Page 2')
    .setColor(0xb5130f)
    .setDescription('Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor '+
        'incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation '+
        'ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in '+
        'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint '+
        'occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.')
    .setAuthor(client.user.username, client.user.avatarURL())
    .setTimestamp(new Date())

let m3: MessageEmbed = new MessageEmbed()
    .setTitle('Page 3')
    .setColor(0xb5130f)
    .setAuthor(client.user.username, client.user.avatarURL())
    .setTimestamp(new Date())

return Pager(message, client, [m1, m2, m3]);
```