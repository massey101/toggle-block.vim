Toggle Block .Vim
===============================================================================

Toggle Block is a vim plugin that will toggle a block within a parentheses
between single and multi-line. This is particular useful for breaking up a long
line while keeping the formatting correct.

Example:
```python
def myfunc(long_arg_name1, long_arg_name2, long_arg_name3, long_arg_name4, long_arg_name5):
    pass
```
Placing the cursor inside the parentheses and press `tb` results in:

```python
def myfunc(
    long_arg_name1,
    long_arg_name2,
    long_arg_name3,
    long_arg_name4,
    long_arg_name5
):
    pass
```
![](https://github.com/massey101/toggle-block.vim/blob/master/static/simpleToggle.gif)

It's even able to handle rather complicated nested brackets.
![](https://github.com/massey101/toggle-block.vim/blob/master/static/complicatedToggle.gif)

It's also able to adapt to json files which don't use a trailing comma.
![](https://gitbub.com/massey101/toggle-block.vim/blob/master/static/jsonToggle.gif)

Installation
-------------------------------------------------------------------------------

Install using your favourite package manager, or use Vim's built-in package
support:

```bash
git clone https://github.com/massey101/toggle-block.vim.git ~/.vim/pack/massey101/start/toggle-block.vim
```

Next map the command in your vimrc. Personally I don't use the function of `t`
which is `cursor till before Nth occurrence of {char} to the right`. So I remap
it like so:

```
nnoremap tb :ToggleBlock<CR>
```
