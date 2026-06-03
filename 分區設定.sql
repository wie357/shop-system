-- ============================================================
-- 泳衣 / 泳褲 分 A/B/C/D 區(貨架/位置),並自動加總
-- 用法:Supabase → SQL Editor → New query → 貼上全部 → Run
-- ============================================================

-- 1) 商品主檔加「分組」欄位(同一組會在盤點時自動加總)
alter table public.products add column if not exists group_name text default '';

-- 2) 移除舊的單一泳衣 / 泳褲
delete from public.products where dept='泳裝部' and code in ('A50','A51');

-- 3) 新增泳衣 A~D 區、泳褲 A~D 區(同 group_name 會加總)
insert into public.products (code,name,dept,category,price,track_stock,active,note,stock,sort,group_name) values
('A50A','泳衣-A區','泳裝部','泳裝',0,true,true,'',0,19,'泳衣'),
('A50B','泳衣-B區','泳裝部','泳裝',0,true,true,'',0,20,'泳衣'),
('A50C','泳衣-C區','泳裝部','泳裝',0,true,true,'',0,21,'泳衣'),
('A50D','泳衣-D區','泳裝部','泳裝',0,true,true,'',0,22,'泳衣'),
('A51A','泳褲-A區','泳裝部','泳裝',0,true,true,'',0,23,'泳褲'),
('A51B','泳褲-B區','泳裝部','泳裝',0,true,true,'',0,24,'泳褲'),
('A51C','泳褲-C區','泳裝部','泳裝',0,true,true,'',0,25,'泳褲'),
('A51D','泳褲-D區','泳裝部','泳裝',0,true,true,'',0,26,'泳褲')
on conflict (dept, code) do nothing;
