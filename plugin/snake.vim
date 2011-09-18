"=============================================================================
" Name: snake.vim
" Author: mfumi
" Email: m.fumi760@gmail.com
" Version: 0.0.1

if exists('g:loaded_snake_vim')
	finish
endif
let g:loaded_snake_vim = 1

let s:save_cpo = &cpo
set cpo&vim

" ----------------------------------------------------------------------------

let s:shape = []
let s:width = 100
let s:height = 18
let s:head = 0
let s:score = 0
let s:direction = 'j'

function! s:set_food()
endfunction

function! s:snake(...)
	
	if a:0 >= 2
		let s:width = a:1
		let s:height = a:2
	else
		let s:width = 100
		let s:height = 18
	endif

	let winnum = bufwinnr(bufnr('\*Snake\*'))
	if winnum != -1
		if winnum != bufwinnr('%')
			exe "normal \<c-w>".winnum."w"
		endif
	else
		exec 'silent split \*Snake\*'
	endif

	setl nonumber
	setl noswapfile
	setl bufhidden=delete
	setl conceallevel=2
	setl modifiable
	setl lazyredraw

	let s:shape = []
	let s:head = 0
	let s:score = 0
	let s:direction = 'j'

	silent %d _
	
	call s:set_status()
	call setline(2,repeat('#',s:width+2))
	for i in range(s:height)
		call setline(i+3,'#'.repeat(' ',s:width).'#')
	endfor
	call setline(s:height+3,repeat('#',s:width+2))
	
	let pos = [0,s:height/2,s:width/2,0]
	call add(s:shape,pos)
	for i in range(len(s:shape))
		call setpos('.',s:shape[i])
		exe "normal rX"
	endfor

	call s:set_food()
	redraw

	if has("conceal")
		syn match SnakeStatusBar contained "|" conceal
	else
		syn match SnakeStatusBar contained "|"
	endif
	syn match SnakeStatus 	'|.*|' contains=SnakeStatusBar
	syn match Snake 		'X'
	syn match SnakeBlock 	'#'
	syn match SnakeFood 	'F'
	hi SnakeStatus 	ctermfg=darkyellow  guifg=darkyellow
	hi Snake 		ctermfg=cyan ctermbg=cyan guifg=cyan guibg=cyan
	hi SnakeBlock	ctermfg=darkblue ctermbg=darkblue guifg=darkblue guibg=darkblue
	hi SnakeFood  	ctermfg=red ctermbg=red guifg=red guibg=red
	nnoremap <buffer> <silent> i :call <SID>start()<CR>

	setl nomodifiable
	setl nomodified
endfunction

function! s:set_status()
	let status = printf("| Score : %d |" , s:score)
	call setline(1,status)
endfunction

function! s:set_food()
	while 1
		let x = (s:rand() % s:width ) + 2
		let y = (s:rand() % s:height) + 3
		let flag = 0
		for pos in s:shape
			if pos[1] == y && pos[2] == x
				let flag = 1
				break
			endif
		endfor
		if flag == 0
			break
		endif
	endwhile
	
	let cur_pos = getpos('.')
	call setpos('.',[0,y,x,0])
	exe "normal rF"
	call setpos('.',cur_pos)
endfunction

function! s:start()
	setl modifiable
	
	while 1
		" remove tail
		let tail = (s:head+1) % len(s:shape)
		call setpos('.',s:shape[tail])
		exe "normal r "

		" check whether key is pressed or not
		let c = getchar(0)
		if c != 0 
			let c = nr2char(c)
			if c == 'h' || c == 'j' || c == 'k' || c == 'l'
				if (s:direction == 'j' && c != 'k') ||
				\  (s:direction == 'k' && c != 'j') ||
				\  (s:direction == 'h' && c != 'l') ||
				\  (s:direction == 'l' && c != 'h') 
					let s:direction = c
				endif
			elseif c == "\<ESC>"
				call s:message("pause")
				break
			endif
		endif

		" move head
		if s:direction == 'h'
			let s:shape[tail][2] = s:shape[s:head][2] - 1
			let s:shape[tail][1] = s:shape[s:head][1]
		elseif s:direction == 'j'
			let s:shape[tail][1] = s:shape[s:head][1] + 1
			let s:shape[tail][2] = s:shape[s:head][2]
		elseif s:direction == 'k'
			let s:shape[tail][1] = s:shape[s:head][1] - 1
			let s:shape[tail][2] = s:shape[s:head][2]
		elseif s:direction == 'l'
			let s:shape[tail][2] = s:shape[s:head][2] + 1
			let s:shape[tail][1] = s:shape[s:head][1]
		endif
		let s:head = tail
		
		" collision check
		if s:shape[s:head][1] <= 2 || s:shape[s:head][1] > (s:height+2) ||
		 		 \ s:shape[s:head][2] <= 1 || s:shape[s:head][2] > (s:width+1)
			call s:message("Ouch!!")
			break
		else
			let flag = 0
			for i in range(len(s:shape))
				if i == s:head | continue | endif
				if s:shape[i][1] == s:shape[s:head][1] && 
							\ s:shape[i][2] == s:shape[s:head][2]
					let flag = 1
					break
				endif
			endfor
			if flag == 1 
				call s:message("Ouch!!")
				break
			endif
		endif

		call setpos('.',s:shape[s:head])
		let c = matchstr(getline('.'),'.',col('.')-1)
		" get food
		if c == 'F' 
			call s:set_food()
			let s:score += 50
			call s:set_status()

			" extend shape
			let tail = (s:head+1) % len(s:shape)
			let y = s:shape[tail][1]
			let x = s:shape[tail][2]
			for i in range(5)
				call insert(s:shape,[0,y,x,0],s:head+1)
			endfor
		endif
		" draw head
		exe "normal rX"

		sleep 100m
		redraw
	endwhile

	setl nomodified
	setl nomodifiable
endfunction

let s:rand_num = 1
function! s:rand()
	if has('reltime')
		let match_end = matchend(reltimestr(reltime()), '\d\+\.') + 1
		return reltimestr(reltime())[l:match_end : ]
	else
		" awful
		let s:rand_num += 1
		return s:rand_num
	endif
endfunction

function! s:message(msg)
	echohl WarningMsg
	echo a:msg
	echohl None
endfunction

command! -nargs=* Snake :call s:snake(<f-args>)


" ----------------------------------------------------------------------------

let &cpo = s:save_cpo
unlet s:save_cpo

