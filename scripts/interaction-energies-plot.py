#!/usr/bin/env python

#!/opt/miniconda3/envs/prolif/bin/python
import seaborn as sns
import pandas as pd
o
import sys

args = sys.argv
ENERGIESFILE = "interaction-energies.csv"
        <F9><F9>ssrr

                            

                            ILE      = "interaction-energies.pdf"



# Read data written in long format
data = pd.read_csv (ENERGIESFILE, index_col=False)
print (data)

# plot
sns.set_theme(font_scale=.8, style="white", context="talk")
g = sns.catplot(
    data=data, x="interaction", y="Frame", hue="interaction", col="residue",
    hue_order=["Hydrophobic", "HBDonor", "HBAcceptor", "PiStacking", "CationPi", "Cationic"],
    height=3, aspect=0.2, jitter=0, sharex=False, marker="_", s=8, linewidth=3.5,
)
g.set_titles("{col_name}")
g.set(xticks=[], ylim=(-.5

    , data.Frame.max()+1))
g.set_xticklabels([])
g.set_xl<F5><F5>

        abels("")
g.fig.subplots_adjust(wspace=0)
g.add_legend()
g.despine(bottom=True)
for

ax in g.axes.flat:
    ax.invert_yaxis()


ax.set_title(ax.get_title(), pad=15, rotation=60, ha="center", va="baseline")

g.savefig (OUTFILE)
//PPoossee



//PPoossee

o
    

    ::qq



::qq<F3><F3>







      


        








o

                









        



qqqq
                    







        








                ccdd

                mmnntt



llggee

                ssddbb11

                xx







ccdd

            <F5><F5>

                    
<F5><F5>....
ttaarr  --zzxxvvff  nnaa..      

llll

ccdd  nnaamm

ddffss

ppwwdd

llll











    





    



















o












        
ddeell  












<F8><F

<F8><F

8>

      





o<F8><F





            











ppddff  --oo

















        



              





        ::      qq

        8>

















        

    

                        mmkkddiirr  00nnss--ttrraajjeeccttoorriieess



      

            



<F5><F5>



        <F5><F5>









                  

                        

                                <F5><F5>

                                          



                                          

        <F6><F6>oolldd



        ll<F5><F5>


mmkkddiirr  ....//olldd



                

irr  nnaammdd--ssww0066





        <F6><F6>




        <F5><F5>
        ++

        <F6><F6>....

      rrmmddiirr    oo

              srr

              ttaarr  --zzxxvvff  wwnnss
