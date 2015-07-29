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

            if (socket.TclOutput.Count > 0 && outputIndex != socket.TclOutput.Count - 1)
            {
                richTextBoxOutput.Text = "";
                richTextBoxOutput.SelectionColor = Color.MediumSeaGreen;
                richTextBoxOutput.AppendText(socket.TclOutput[socket.TclOutput.Count-1] + "\n");

            }

            richTextBoxLog.Text = "";
            richTextBoxLog.SelectionColor = Color.BlueViolet;
            foreach(string log in socket.TclOutput)
            {
                richTextBoxLog.AppendText(log + "\n");
            }

            richTextBoxError.Text = "";
            richTextBoxError.SelectionColor = Color.Red;
            foreach (string log in socket.TclErr)
            {
                richTextBoxError.AppendText(log + "\n");
            }
        }


        
    }
}
