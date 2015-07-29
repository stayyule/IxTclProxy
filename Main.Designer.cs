namespace IxTclProxy
{
    partial class Main
    {
        /// <summary>
        /// 必需的设计器变量。
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// 清理所有正在使用的资源。
        /// </summary>
        /// <param name="disposing">如果应释放托管资源，为 true；否则为 false。</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows 窗体设计器生成的代码

        /// <summary>
        /// 设计器支持所需的方法 - 不要
        /// 使用代码编辑器修改此方法的内容。
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            this.toolStripControl = new System.Windows.Forms.ToolStrip();
            this.toolStripButtonStart = new System.Windows.Forms.ToolStripButton();
            this.toolStripButtonStop = new System.Windows.Forms.ToolStripButton();
            this.toolStripSeparator2 = new System.Windows.Forms.ToolStripSeparator();
            this.toolStripLabel1 = new System.Windows.Forms.ToolStripLabel();
            this.toolStripTextBoxTclInterp = new System.Windows.Forms.ToolStripTextBox();
            this.toolStripButtonBrowse = new System.Windows.Forms.ToolStripButton();
            this.toolStripSeparator1 = new System.Windows.Forms.ToolStripSeparator();
            this.toolStripLabel2 = new System.Windows.Forms.ToolStripLabel();
            this.toolStripTextBoxAgentPort = new System.Windows.Forms.ToolStripTextBox();
            this.richTextBoxOutput = new System.Windows.Forms.RichTextBox();
            this.openFileDialogTclShell = new System.Windows.Forms.OpenFileDialog();
            this.timerOutput = new System.Windows.Forms.Timer(this.components);
            this.splitContainerOutput = new System.Windows.Forms.SplitContainer();
            this.tabControlLog = new System.Windows.Forms.TabControl();
            this.tabPage1 = new System.Windows.Forms.TabPage();
            this.richTextBoxLog = new System.Windows.Forms.RichTextBox();
            this.tabPage2 = new System.Windows.Forms.TabPage();
            this.richTextBoxError = new System.Windows.Forms.RichTextBox();
            this.toolStripControl.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainerOutput)).BeginInit();
            this.splitContainerOutput.Panel1.SuspendLayout();
            this.splitContainerOutput.Panel2.SuspendLayout();
            this.splitContainerOutput.SuspendLayout();
            this.tabControlLog.SuspendLayout();
            this.tabPage1.SuspendLayout();
            this.tabPage2.SuspendLayout();
            this.SuspendLayout();
            // 
            // toolStripControl
            // 
            this.toolStripControl.GripStyle = System.Windows.Forms.ToolStripGripStyle.Hidden;
            this.toolStripControl.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.toolStripButtonStart,
            this.toolStripButtonStop,
            this.toolStripSeparator2,
            this.toolStripLabel1,
            this.toolStripTextBoxTclInterp,
            this.toolStripButtonBrowse,
            this.toolStripSeparator1,
            this.toolStripLabel2,
            this.toolStripTextBoxAgentPort});
            this.toolStripControl.Location = new System.Drawing.Point(0, 0);
            this.toolStripControl.Name = "toolStripControl";
            this.toolStripControl.Size = new System.Drawing.Size(496, 25);
            this.toolStripControl.TabIndex = 0;
            // 
            // toolStripButtonStart
            // 
            this.toolStripButtonStart.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Image;
            this.toolStripButtonStart.Image = global::IxTclProxy.Properties.Resources.play_16;
            this.toolStripButtonStart.ImageTransparentColor = System.Drawing.Color.Magenta;
            this.toolStripButtonStart.Name = "toolStripButtonStart";
            this.toolStripButtonStart.Size = new System.Drawing.Size(23, 22);
            this.toolStripButtonStart.Text = "start";
            this.toolStripButtonStart.Click += new System.EventHandler(this.toolStripButtonStart_Click);
            // 
            // toolStripButtonStop
            // 
            this.toolStripButtonStop.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Image;
            this.toolStripButtonStop.Image = global::IxTclProxy.Properties.Resources.splay_16;
            this.toolStripButtonStop.ImageTransparentColor = System.Drawing.Color.Magenta;
            this.toolStripButtonStop.Name = "toolStripButtonStop";
            this.toolStripButtonStop.Size = new System.Drawing.Size(23, 22);
            this.toolStripButtonStop.Text = "stop";
            this.toolStripButtonStop.Click += new System.EventHandler(this.toolStripButtonStop_Click);
            // 
            // toolStripSeparator2
            // 
            this.toolStripSeparator2.Name = "toolStripSeparator2";
            this.toolStripSeparator2.Size = new System.Drawing.Size(6, 25);
            // 
            // toolStripLabel1
            // 
            this.toolStripLabel1.Name = "toolStripLabel1";
            this.toolStripLabel1.Size = new System.Drawing.Size(56, 22);
            this.toolStripLabel1.Text = "tcl解释器";
            // 
            // toolStripTextBoxTclInterp
            // 
            this.toolStripTextBoxTclInterp.Name = "toolStripTextBoxTclInterp";
            this.toolStripTextBoxTclInterp.Size = new System.Drawing.Size(200, 25);
            // 
            // toolStripButtonBrowse
            // 
            this.toolStripButtonBrowse.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Image;
            this.toolStripButtonBrowse.Image = global::IxTclProxy.Properties.Resources.open_16;
            this.toolStripButtonBrowse.ImageTransparentColor = System.Drawing.Color.Magenta;
            this.toolStripButtonBrowse.Name = "toolStripButtonBrowse";
            this.toolStripButtonBrowse.Size = new System.Drawing.Size(23, 22);
            this.toolStripButtonBrowse.Click += new System.EventHandler(this.toolStripButtonBrowse_Click);
            // 
            // toolStripSeparator1
            // 
            this.toolStripSeparator1.Name = "toolStripSeparator1";
            this.toolStripSeparator1.Size = new System.Drawing.Size(6, 25);
            // 
            // toolStripLabel2
            // 
            this.toolStripLabel2.Name = "toolStripLabel2";
            this.toolStripLabel2.Size = new System.Drawing.Size(55, 22);
            this.toolStripLabel2.Text = "代理端口";
            // 
            // toolStripTextBoxAgentPort
            // 
            this.toolStripTextBoxAgentPort.Name = "toolStripTextBoxAgentPort";
            this.toolStripTextBoxAgentPort.Size = new System.Drawing.Size(50, 25);
            this.toolStripTextBoxAgentPort.Text = "4555";
            // 
            // richTextBoxOutput
            // 
            this.richTextBoxOutput.Dock = System.Windows.Forms.DockStyle.Fill;
            this.richTextBoxOutput.Location = new System.Drawing.Point(0, 0);
            this.richTextBoxOutput.Name = "richTextBoxOutput";
            this.richTextBoxOutput.ReadOnly = true;
            this.richTextBoxOutput.Size = new System.Drawing.Size(496, 139);
            this.richTextBoxOutput.TabIndex = 1;
            this.richTextBoxOutput.Text = "";
            // 
            // openFileDialogTclShell
            // 
            this.openFileDialogTclShell.FileName = "ixiawish";
            // 
            // timerOutput
            // 
            this.timerOutput.Interval = 2000;
            this.timerOutput.Tick += new System.EventHandler(this.timerOutput_Tick);
            // 
            // splitContainerOutput
            // 
            this.splitContainerOutput.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainerOutput.Location = new System.Drawing.Point(0, 25);
            this.splitContainerOutput.Name = "splitContainerOutput";
            this.splitContainerOutput.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainerOutput.Panel1
            // 
            this.splitContainerOutput.Panel1.Controls.Add(this.richTextBoxOutput);
            // 
            // splitContainerOutput.Panel2
            // 
            this.splitContainerOutput.Panel2.Controls.Add(this.tabControlLog);
            this.splitContainerOutput.Size = new System.Drawing.Size(496, 333);
            this.splitContainerOutput.SplitterDistance = 139;
            this.splitContainerOutput.TabIndex = 2;
            // 
            // tabControlLog
            // 
            this.tabControlLog.Controls.Add(this.tabPage1);
            this.tabControlLog.Controls.Add(this.tabPage2);
            this.tabControlLog.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tabControlLog.Location = new System.Drawing.Point(0, 0);
            this.tabControlLog.Name = "tabControlLog";
            this.tabControlLog.SelectedIndex = 0;
            this.tabControlLog.Size = new System.Drawing.Size(496, 190);
            this.tabControlLog.TabIndex = 4;
            // 
            // tabPage1
            // 
            this.tabPage1.Controls.Add(this.richTextBoxLog);
            this.tabPage1.Location = new System.Drawing.Point(4, 22);
            this.tabPage1.Name = "tabPage1";
            this.tabPage1.Padding = new System.Windows.Forms.Padding(3);
            this.tabPage1.Size = new System.Drawing.Size(488, 164);
            this.tabPage1.TabIndex = 0;
            this.tabPage1.Text = "LOG";
            this.tabPage1.UseVisualStyleBackColor = true;
            // 
            // richTextBoxLog
            // 
            this.richTextBoxLog.Dock = System.Windows.Forms.DockStyle.Fill;
            this.richTextBoxLog.Location = new System.Drawing.Point(3, 3);
            this.richTextBoxLog.Name = "richTextBoxLog";
            this.richTextBoxLog.ReadOnly = true;
            this.richTextBoxLog.Size = new System.Drawing.Size(482, 158);
            this.richTextBoxLog.TabIndex = 3;
            this.richTextBoxLog.Text = "";
            // 
            // tabPage2
            // 
            this.tabPage2.Controls.Add(this.richTextBoxError);
            this.tabPage2.Location = new System.Drawing.Point(4, 22);
            this.tabPage2.Name = "tabPage2";
            this.tabPage2.Padding = new System.Windows.Forms.Padding(3);
            this.tabPage2.Size = new System.Drawing.Size(488, 164);
            this.tabPage2.TabIndex = 1;
            this.tabPage2.Text = "ERR";
            this.tabPage2.UseVisualStyleBackColor = true;
            // 
            // richTextBoxError
            // 
            this.richTextBoxError.Dock = System.Windows.Forms.DockStyle.Fill;
            this.richTextBoxError.Location = new System.Drawing.Point(3, 3);
            this.richTextBoxError.Name = "richTextBoxError";
            this.richTextBoxError.ReadOnly = true;
            this.richTextBoxError.Size = new System.Drawing.Size(482, 158);
            this.richTextBoxError.TabIndex = 0;
            this.richTextBoxError.Text = "";
            // 
            // Main
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(496, 358);
            this.Controls.Add(this.splitContainerOutput);
            this.Controls.Add(this.toolStripControl);
            this.Name = "Main";
            this.Text = "IxTclProxy";
            this.toolStripControl.ResumeLayout(false);
            this.toolStripControl.PerformLayout();
            this.splitContainerOutput.Panel1.ResumeLayout(false);
            this.splitContainerOutput.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainerOutput)).EndInit();
            this.splitContainerOutput.ResumeLayout(false);
            this.tabControlLog.ResumeLayout(false);
            this.tabPage1.ResumeLayout(false);
            this.tabPage2.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.ToolStrip toolStripControl;
        private System.Windows.Forms.ToolStripButton toolStripButtonStart;
        private System.Windows.Forms.ToolStripButton toolStripButtonStop;
        private System.Windows.Forms.RichTextBox richTextBoxOutput;
        private System.Windows.Forms.ToolStripLabel toolStripLabel1;
        private System.Windows.Forms.ToolStripTextBox toolStripTextBoxTclInterp;
        private System.Windows.Forms.ToolStripButton toolStripButtonBrowse;
        private System.Windows.Forms.ToolStripSeparator toolStripSeparator1;
        private System.Windows.Forms.ToolStripLabel toolStripLabel2;
        private System.Windows.Forms.ToolStripTextBox toolStripTextBoxAgentPort;
        private System.Windows.Forms.ToolStripSeparator toolStripSeparator2;
        private System.Windows.Forms.OpenFileDialog openFileDialogTclShell;
        private System.Windows.Forms.Timer timerOutput;
        private System.Windows.Forms.SplitContainer splitContainerOutput;
        private System.Windows.Forms.RichTextBox richTextBoxLog;
        private System.Windows.Forms.TabControl tabControlLog;
        private System.Windows.Forms.TabPage tabPage1;
        private System.Windows.Forms.TabPage tabPage2;
        private System.Windows.Forms.RichTextBox richTextBoxError;

    }
}

