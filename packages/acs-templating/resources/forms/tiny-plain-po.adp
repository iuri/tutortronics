<!-- Form elements -->
<table class="filter-table">
  <multiple name=elements>

    <if @elements.section@ not nil>
      <tr bgcolor="#ccccff"><th colspan="2">@elements.section@</th></tr>
    </if>

    <group column="section">
      <if @elements.widget@ eq "hidden"> 
        <noparse><formwidget id=@elements.id@></noparse>
      </if>
  
      <else>

        <if @elements.widget@ eq "submit">
          <tr>
            <td align="center" colspan="2">
              <group column="widget">
                <noparse>
                  <formwidget id="@elements.id@">
                </noparse>
              </group>
            </td>
          </tr>
        </if>
        <else>
          <tr>
            <if @elements.label@ not nil>
              <noparse>
                <if \@formerror.@elements.id@\@ not nil>
                  <td bgcolor="#ffaaaa">
                </if>
                <else>
                  <td bgcolor="#ffffff">
                </else>
              </noparse>@elements.label;noquote@&nbsp;&nbsp;</td>
            </if>
            <else>
              <td bgcolor="#ffffff">
                &nbsp;
              </td>
            </else>

              <noparse>
                <if \@formerror.@elements.id@\@ not nil>
                  <td style="border: 2px solid red;">
                </if>
                <else>
                  <td>
                </else>
              </noparse>

              <if @elements.widget@ eq radio or @elements.widget@ eq checkbox>
                <noparse>
                  <table cellpadding="4" cellspacing="0" border="0">
                    <formgroup id="@elements.id@">
                      <tr>
                        <td>\@formgroup.widget;noquote@</td>
                        <td>
			   <span class="po_form_element">
                            <label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option@">
                              \@formgroup.label@
                            </label>
                          </span>
                        </td>
                      </tr>
                    </formgroup>
                  </table>
                </noparse>
              </if>

              <else>
                <span class="po_form_element">
                  <noparse>
                    <formwidget id="@elements.id@">
                  </noparse>
                </span>
              </else>

              <noparse>
                <formerror id="@elements.id@">
                  <br>
		   <span class="po_form_element_error">
                    <b>\@formerror.@elements.id@;noquote\@<b>
                  </span>
                </formerror>
              </noparse>

              <if @elements.help_text@ not nil>
		<span class="po_form_element_help">
                    <noparse>
                      <i><formhelp id="@elements.id@"></i>
                    </noparse>
                </span>
                </p>
              </if>

            </td>
          </tr>
        </else>
      </else>
    </group>
  </multiple>

</table>
