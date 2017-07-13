using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.IO;

using BitTcl;

namespace IxTclProxy
{
    public partial class Main : Form
    {

        private TestCase socket;
        private int outputIndex = -1;

        public Main()
        {
            InitializeComponent();
            
        }

        private void toolStripButtonStart_Click(object sender, EventArgs e)
        {
            if(!File.Exists(toolStripTextBoxTclInterp.Text))
            {
                MessageBox.Show("解释器文件不存在，请检查解释器路径。","解释器不存在", MessageBoxButtons.OK);
                return;
            }

            int port = 0;
            if (!int.TryParse(toolStripTextBoxAgentPort.Text, out port))
            {
                MessageBox.Show("端口错误，请输入有效端口。", "端口错误", MessageBoxButtons.OK);
                return;
 
            }

            socket = new TestCase(Properties.Resources.Socket, toolStripTextBoxTclInterp.Text);
            socket.Run();
            socket.WriteToTcl(toolStripTextBoxAgentPort.Text);

            timerOutput.Start();
            toolStripButtonStart.Enabled = false;
            toolStripButtonStop.Enabled = true;
        }

        private void toolStripButtonStop_Click(object sender, EventArgs e)
        {
            if (socket == null)
            {
                return;
            }
            socket.Stop();
            timerOutput.Stop();
            toolStripButtonStart.Enabled = true;
            toolStripButtonStop.Enabled = false;
        }

        private void toolStripButtonBrowse_Click(object sender, EventArgs e)
        {
            DialogResult result = openFileDialogTclShell.ShowDialog();
            if (result == System.Windows.Forms.DialogResult.OK)
            {
                toolStripTextBoxTclInterp.Text = openFileDialogTclShell.FileName;
            }
        }

        private void timerOutput_Tick(object sender, EventArgs e)
        {
            if (socket==null)
            {
                return;
            }

            richTextBoxOutput.Text = "";
            richTextBoxLog.Text = "";
            richTextBoxError.Text = "";

            int count = socket.TclOutput.Count;
            int startIndex = 0;
            if (count > 0)
            {
                if (count > 100)
                {
                    startIndex = count - 100;
                }
                List<string> outputRange = socket.TclOutput.GetRange(startIndex, count - startIndex);

                if (outputRange.Count > 0 && outputIndex != outputRange.Count - 1)
                {
                    richTextBoxOutput.SelectionColor = Color.MediumSeaGreen;
                    richTextBoxOutput.AppendText(outputRange[outputRange.Count - 1] + "\n");

                }

                richTextBoxLog.SelectionColor = Color.BlueViolet;
                foreach (string log in outputRange)
                {
                    richTextBoxLog.AppendText(log + "\n");
                }
            }
            count = socket.TclErr.Count;
            startIndex = 0;
            if (count > 0)
            {
                if (count > 50)
                {
                    startIndex = count - 50;
                }
                List<string> outputErrRange = socket.TclErr.GetRange(startIndex, count - startIndex);

                richTextBoxError.SelectionColor = Color.Red;
                foreach (string log in outputErrRange)
                {
                    richTextBoxError.AppendText(log + "\n");
                }
            }
        }  
    }
}
