## AsyncCmdProcessor.vim

This is a small plugin for vim 8.0+ which manages to run commands asynchronously and reports the output in a vim buffer.
For simplicity the plugin allows to only run one asynchronous command at a time.

### Basic Usage

The plugin exports the following command `:Async` to run jobs asynchronously. It can be used like this:
```
:Async ls
:Async scons -j16 test
:Async find . -type f -exec grep -nHI function {} +
```
The output from stdout/stderr is collected in the named buffer `async_buffer`.

### Optional Configuration

The name of the output buffer can be influenced with the following variable:
```
let g:gACP_buffer_name = 'some_name'
```

### Exported Keymaps

The plugin exports the following keymaps for the `normal` mode:
```
<leader>a   -  Puts :Async in vim command line to submit a asynchronous job.
<leader>ab  -  Switch to async_buffer in current window.
<leader>ak  -  Kill the current asynchronous job.
```

### Exported Functions

The plugin exports the following function(s):
```
GetAsyncJobStatus()  -  Return the status of the currently running / last finished job.
                        The returned string has the following format '<job_status>:<return_value>'
```
