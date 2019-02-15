/*
 * yui-ext 0.33
 * Copyright(c) 2006, Jack Slocum.
 */


YAHOO.ext.grid.PagedGridView=function(){YAHOO.ext.grid.PagedGridView.superclass.constructor.call(this);this.cursor=1;};YAHOO.extendX(YAHOO.ext.grid.PagedGridView,YAHOO.ext.grid.GridView,{appendFooter:function(parentEl){var fwrap=document.createElement('div');fwrap.className='ygrid-wrap-footer';var fbody=document.createElement('span');fbody.className='ygrid-footer';fwrap.appendChild(fbody);parentEl.appendChild(fwrap);this.createPagingToolbar(fbody);return fwrap;},createPagingToolbar:function(container){var tb=new YAHOO.ext.Toolbar(container);this.pageToolbar=tb;this.first=tb.addButton({tooltip:this.firstText,className:'ygrid-page-first',disabled:true,click:this.onClick.createDelegate(this,['first'])});this.prev=tb.addButton({tooltip:this.prevText,className:'ygrid-page-prev',disabled:true,click:this.onClick.createDelegate(this,['prev'])});tb.addSeparator();tb.add(this.beforePageText);var pageBox=document.createElement('input');pageBox.type='text';pageBox.size=3;pageBox.value='1';pageBox.className='ygrid-page-number';tb.add(pageBox);this.field=getEl(pageBox,true);this.field.mon('keydown',this.onEnter,this,true);this.field.on('focus',function(){pageBox.select();});this.afterTextEl=tb.addText(this.afterPageText.replace('%0','1'));this.field.setHeight(18);tb.addSeparator();this.next=tb.addButton({tooltip:this.nextText,className:'ygrid-page-next',disabled:true,click:this.onClick.createDelegate(this,['next'])});this.last=tb.addButton({tooltip:this.lastText,className:'ygrid-page-last',disabled:true,click:this.onClick.createDelegate(this,['last'])});tb.addSeparator();this.loading=tb.addButton({tooltip:this.refreshText,className:'ygrid-loading',disabled:true,click:this.onClick.createDelegate(this,['refresh'])});this.onPageLoaded(1,this.grid.dataModel.getTotalPages());},getPageToolbar:function(){return this.pageToolbar;},onPageLoaded:function(pageNum,totalPages){this.cursor=pageNum;this.lastPage=totalPages;this.afterTextEl.innerHTML=this.afterPageText.replace('%0',totalPages);this.field.dom.value=pageNum;this.first.setDisabled(pageNum==1);this.prev.setDisabled(pageNum==1);this.next.setDisabled(pageNum==totalPages);this.last.setDisabled(pageNum==totalPages);this.loading.enable();},onLoadError:function(){this.loading.enable();},onEnter:function(e){if(e.browserEvent.keyCode==e.RETURN){var v=this.field.dom.value;if(!v){this.field.dom.value=this.cursor;return;}
var pageNum=parseInt(v,10);if(isNaN(pageNum)){this.field.dom.value=this.cursor;return;}
pageNum=Math.min(Math.max(1,pageNum),this.lastPage);this.grid.dataModel.loadPage(pageNum);e.stopEvent();}},beforeLoad:function(){this.grid.stopEditing();if(this.loading){this.loading.disable();}},onClick:function(which){switch(which){case'first':this.grid.dataModel.loadPage(1);break;case'prev':this.grid.dataModel.loadPage(this.cursor-1);break;case'next':this.grid.dataModel.loadPage(this.cursor+1);break;case'last':this.grid.dataModel.loadPage(this.lastPage);break;case'refresh':this.grid.dataModel.loadPage(this.cursor);break;}},unplugDataModel:function(dm){dm.removeListener('beforeload',this.beforeLoad,this);dm.removeListener('load',this.onPageLoaded,this);dm.removeListener('loadexception',this.onLoadError,this);YAHOO.ext.grid.PagedGridView.superclass.unplugDataModel.call(this,dm);},plugDataModel:function(dm){dm.on('beforeload',this.beforeLoad,this,true);dm.on('load',this.onPageLoaded,this,true);dm.on('loadexception',this.onLoadError,this);YAHOO.ext.grid.PagedGridView.superclass.plugDataModel.call(this,dm);},beforePageText:"Page",afterPageText:"of %0",firstText:"First Page",prevText:"Previous Page",nextText:"Next Page",lastText:"Last Page",refreshText:"Refresh"});